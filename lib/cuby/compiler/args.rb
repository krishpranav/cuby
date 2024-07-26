module Cuby
  class Compiler
    class Args
      def initialize(pass, local_only: true, for_block: false)
        @pass = pass
        @local_only = local_only
        @for_block = for_block
        @underscore_arg_set = false
      end

      def transform(node)
        @from_side = :left
        @instructions = []
        if node.instance_of?(Array)
          @args = node
        elsif node.is_a?(::Prism::MultiTargetNode)
          @args = node.lefts + [node.rest].compact + node.rights
        else
          raise "unhandled node: #{node.inspect}"
        end
        while @args.any?
          arg = @from_side == :left ? @args.shift : @args.pop
          if transform_arg(arg) == :reverse
            @from_side = { left: :right, right: :left }.fetch(@from_side)
          end
        end
        clean_up
      end

      private

      def transform_arg(arg)
        case arg
        when ::Prism::LocalVariableTargetNode
          clean_up_keyword_args
          transform_required_arg(arg)
        when ::Prism::MultiTargetNode
          clean_up_keyword_args
          transform_destructured_arg(arg)
        when ::Prism::OptionalParameterNode
          clean_up_keyword_args
          transform_optional_arg(arg)
        when ::Prism::SplatNode
          clean_up_keyword_args
          transform_splat_arg(arg)
        when ::Prism::ArrayNode
          clean_up_keyword_args
          transform_destructured_arg(arg)
        when ::Prism::InstanceVariableTargetNode
          transform_instance_variable_arg(arg)
        when ::Prism::ClassVariableTargetNode
          transform_class_variable_arg(arg)
        when ::Prism::GlobalVariableTargetNode
          transform_global_variable_arg(arg)
        when ::Prism::ConstantTargetNode
          transform_constant_arg(arg)
        when ::Prism::CallTargetNode
          transform_call_arg(arg)
        when ::Prism::IndexTargetNode
          transform_index_arg(arg)
        when ::Prism::RequiredParameterNode
          clean_up_keyword_args
          transform_required_arg(arg)
        when ::Prism::NumberedParametersNode
          transform_numbered_arg(arg)
        when ::Prism::RestParameterNode
          clean_up_keyword_args
          transform_rest_arg(arg)
        when ::Prism::KeywordRestParameterNode
          transform_keyword_splat_arg(arg)
        when ::Prism::RequiredKeywordParameterNode
          transform_required_keyword_arg(arg)
        when ::Prism::OptionalKeywordParameterNode
          transform_optional_keyword_arg(arg)
        when ::Prism::NoKeywordsParameterNode
          transform_no_keyword_arg(arg)
        when ::Prism::ImplicitRestNode
          clean_up_keyword_args
          transform_implicit_rest_arg(arg)
        else
          raise "unhandled node: #{arg.inspect} (#{@pass.file.path}##{arg.location.start_line})"
        end
      end

      def remaining_required_args
        @args.select do |arg|
          arg.is_a?(::Prism::RequiredParameterNode)
        end
      end

      def remaining_keyword_args
        @args.select do |arg|
          arg.is_a?(::Prism::RequiredKeywordParameterNode) ||
          arg.is_a?(::Prism::OptionalKeywordParameterNode)
        end
      end

      def kwsplat?
        @args.any? do |arg|
          arg.is_a?(::Prism::KeywordRestParameterNode)
        end
      end

      def transform_required_arg(arg)
        shift_or_pop_next_arg
        @instructions << variable_set(arg.name)
      end

      def transform_numbered_arg(arg)
        arg.maximum.times do |i|
          shift_or_pop_next_arg
          @instructions << variable_set(:"_#{i + 1}")
        end
      end

      def transform_optional_arg(arg)
        if remaining_required_args.any?
          @args.unshift(arg)
          return :reverse
        elsif remaining_keyword_args.any? || kwsplat?
          @args.unshift(arg)
          return :reverse
        elsif @from_side == :right
          @args.push(arg)
          return :reverse
        end

        name = arg.name
        default_value = arg.value

        if default_value&.type == :local_variable_read_node && default_value.name == name
          raise SyntaxError, "circular argument reference - #{name}"
        end

        @instructions << @pass.transform_expression(default_value, used: true)
        shift_or_pop_next_arg_with_default
        @instructions << variable_set(name)
      end

      def transform_required_keyword_arg(arg)
        move_keyword_arg_hash_from_args_array_to_stack
        @instructions << HashDeleteInstruction.new(arg.name)
        @instructions << variable_set(arg.name)
      end

      def transform_optional_keyword_arg(arg)
        move_keyword_arg_hash_from_args_array_to_stack
        @instructions << @pass.transform_expression(arg.value, used: true)
        @instructions << HashDeleteWithDefaultInstruction.new(arg.name)
        @instructions << variable_set(arg.name)
      end

      def transform_no_keyword_arg(arg)
        move_keyword_arg_hash_from_args_array_to_stack
      end

      def transform_destructured_arg(arg)
        @instructions << ArrayShiftInstruction.new
        @instructions << DupInstruction.new
        @instructions << ToArrayInstruction.new
        sub_processor = self.class.new(@pass, local_only: @local_only, for_block: @for_block)
        @instructions << sub_processor.transform(arg)
        @instructions << PopInstruction.new
      end

      def transform_instance_variable_arg(arg)
        @instructions << ArrayShiftInstruction.new
        @instructions << InstanceVariableSetInstruction.new(arg.name)
      end

      def transform_class_variable_arg(arg)
        @instructions << ArrayShiftInstruction.new
        @instructions << ClassVariableSetInstruction.new(arg.name)
      end

      def transform_global_variable_arg(arg)
        @instructions << ArrayShiftInstruction.new
        @instructions << GlobalVariableSetInstruction.new(arg.name)
      end

      def transform_constant_arg(arg)
        @instructions << ArrayShiftInstruction.new
        @instructions << PushSelfInstruction.new
        @instructions << ConstSetInstruction.new(arg.name)
      end

      def transform_call_arg(arg)
        @instructions << ArrayShiftInstruction.new
        @instructions.concat(@pass.transform_expression(arg.receiver, used: true))
        if arg.safe_navigation?
          @instructions << DupInstruction.new
          @instructions << IsNilInstruction.new
          @instructions << IfInstruction.new
          @instructions << PopInstruction.new
          @instructions << ElseInstruction.new(:if)
        end
        @instructions << SwapInstruction.new
        @instructions << PushArgcInstruction.new(1)
        @instructions << SendInstruction.new(
          arg.name,
          args_array_on_stack: false,
          receiver_is_self: arg.receiver.is_a?(Prism::SelfNode),
          with_block: false,
          has_keyword_hash: false,
          file: @pass.file.path,
          line: arg.location.start_line,
        )
        if arg.safe_navigation?
          @instructions << EndInstruction.new(:if)
        end
      end

      def transform_index_arg(arg)
        @instructions << ArrayShiftInstruction.new
        @instructions.concat(@pass.transform_expression(arg.receiver, used: true))
        @instructions << SwapInstruction.new
        arg.arguments.arguments.each do |argument|
          @instructions.concat(@pass.transform_expression(argument, used: true))
          @instructions << SwapInstruction.new
        end
        @instructions << PushArgcInstruction.new(arg.arguments.arguments.size + 1)
        @instructions << SendInstruction.new(
          :[]=,
          args_array_on_stack: false,
          receiver_is_self: arg.receiver.is_a?(Prism::SelfNode),
          with_block: false,
          has_keyword_hash: false,
          file: @pass.file.path,
          line: arg.location.start_line,
        )
      end

      def transform_rest_arg(arg)
        if (name = arg.name)
          @instructions << variable_set(name)
          @instructions << VariableGetInstruction.new(name)
        end
        :reverse
      end

      def transform_splat_arg(arg)
        if arg.expression
          if @for_block
            unless [:local_variable_target_node, :required_parameter_node].include?(arg.expression.type)
              raise "I don't know how to splat #{arg.expression.inspect}"
            end
          else
            unless arg.expression.type == :required_parameter_node
              raise "I don't know how to splat #{arg.expression.inspect}"
            end
          end

          name = arg.expression.name
        end
        if name
          @instructions << variable_set(name)
          @instructions << VariableGetInstruction.new(name)
        end
        :reverse
      end

      def transform_keyword_splat_arg(arg)
        move_keyword_arg_hash_from_args_array_to_stack
        if arg.name
          @instructions << variable_set(arg.name)
          @instructions << VariableGetInstruction.new(arg.name)
        end
        @has_keyword_splat = true
        :reverse unless remaining_keyword_args.any?
      end

      def transform_implicit_rest_arg(arg)
        :reverse
      end

      def variable_set(name)
        raise "bad var name: #{name.inspect}" unless name =~ /^(?:[[:alpha:]]|_)[[:alnum:]]*/

        if name == :_
          if @underscore_arg_set
            return PopInstruction.new
          else
            @underscore_arg_set = true
          end
        end

        VariableSetInstruction.new(name, local_only: @local_only)
      end

      def shift_or_pop_next_arg
        if @from_side == :left
          @instructions << ArrayShiftInstruction.new
        else
          @instructions << ArrayPopInstruction.new
        end
      end

      def shift_or_pop_next_arg_with_default
        if @from_side == :left
          @instructions << ArrayShiftWithDefaultInstruction.new
        else
          @instructions << ArrayPopWithDefaultInstruction.new
        end
      end

      def move_keyword_arg_hash_from_args_array_to_stack
        return if @keyword_arg_hash_on_stack

        @instructions << SwapInstruction.new
        @keyword_arg_hash_on_stack = true
      end

      def clean_up_keyword_args
        if @keyword_arg_hash_on_stack
          @instructions << CheckExtraKeywordsInstruction.new unless @has_keyword_splat
          @instructions << PopInstruction.new
        end
        @keyword_arg_hash_on_stack = false
      end

      def clean_up
        clean_up_keyword_args
        @instructions << PopInstruction.new
      end
    end
  end
end