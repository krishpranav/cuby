module Cuby
    class Compiler
        class Arity 
            def initialize(args, is_proc:)
                args = args.parameters if args.is_a?(Prism::BlockParametersNode)
                @node = args
                case args
                when nil
                    @args = []
                when ::Prism::ParamteersNode
                    @args = (
                        args.requireds +
                        [args.rest] +
                        args.optionals +
                        args.posts +
                        args.keywords +
                        [args.keyword_rest]
                    ).compact
                when ::Prism::NumberedParametersNode
                    @args = args.maximum.times.map do |i|
                        Prism::RequiredParameterNode.new(nil, nil, :"_#{i + 1}", args.location)
                    end
                else
                    raise "expected args node, but got #{args.inspect}"
                end
                @is_proc = is_proc
            end

            attr_reader :args

            def arity

            end