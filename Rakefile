require_relative './lib/cuby/compiler/flags'

task default: :build

DEFAULT_BUILD_TYPE = 'debug'.freeze
DL_EXT = RbConfig::CONFIG['DLEXT']
SO_EXT = RbConfig::CONFIG['SOEXT']
SRC_DIRECTORIES = Dir.new('src').children.select { |p| File.directory?(File.join('src', p)) }

desc 'Build Cuby'
task :build do
  type = File.exist?('.build') ? File.read('.build') : DEFAULT_BUILD_TYPE
  Rake::Task["build_#{type}"].invoke
end

desc 'Build Cuby with no optimization and all warnings (default)'
task build_debug: %i[set_build_debug libcuby prism_c_ext ctags] do
  puts 'Build mode: debug'
end

desc 'Build Cuby with AddressSanitizer enabled'
task build_asan: %i[set_build_asan libcuby prism_c_ext] do
  puts 'Build mode: asan'
end

desc 'Build Cuby with release optimizations enabled and warnings off'
task build_release: %i[set_build_release libcuby prism_c_ext] do
  puts 'Build mode: release'
end

desc 'Remove temporary files created during build'
task :clean do
  SRC_DIRECTORIES.each do |subdir|
    path = File.join('build', subdir)
    rm_rf path
  end
  rm_rf 'build/build.log'
  rm_rf 'build/generated'
  rm_rf 'build/libcuby_base.a'
  rm_rf "build/libcuby_base.#{DL_EXT}"
  rm_rf "build/libnat.#{SO_EXT}"
  rm_rf Rake::FileList['build/*.o']
end

desc 'Remove all generated files'
task :clobber do
  rm_rf 'build'
  rm_rf '.build'
end

task distclean: :clobber

desc 'Run the test suite'
task test: %i[build build_test_support] do
  sh 'bundle exec ruby test/all.rb'
end

desc 'Run the most-recently-modified test'
task test_last_modified: :build do
  last_edited = Dir['test/**/*_test.rb', 'spec/**/*_spec.rb'].max_by { |path| File.stat(path).mtime.to_i }
  sh ['bin/cuby', '-I', 'test/support', ENV['FLAGS'], last_edited].compact.join(' ')
end

desc 'Run a folder with tests'
task :test_folder, [:folder] => :build do |task, args|
  if args[:folder].nil?
    warn("Please run with the folder as argument: `rake #{task.name}[<spec/X/Y>]")
    exit(1)
  elsif !File.directory?(args[:folder])
    warn("The folder #{args[:folder]} does not exist or is not a directory")
    exit(1)
  else
    specs = Dir["#{args[:folder]}/**/*_test.rb", "#{args[:folder]}/**/*_spec.rb"]
    sh ['bin/cuby', 'test/runner.rb', specs.to_a].join(' ')
  end
end

desc 'Run the most-recently-modified test when any source files change (requires entr binary)'
task :watch do
  files = Rake::FileList['**/*.cpp', '**/*.c', '**/*.hpp', '**/*.rb'].exclude('{build,ext}/**/*')
  sh "ls #{files} | entr -c -s 'rake test_last_modified'"
end

desc 'Test that the self-hosted compiler builds and runs a core subset of the tests'
task test_self_hosted: %i[bootstrap build_test_support] do
  sh 'bin/nat --version'
  env = {
    'NAT_BINARY' => 'bin/nat',
    'GLOB'       => 'spec/language/*_spec.rb',
  }
  sh env, 'bundle exec ruby test/all.rb'
end

desc 'Test that the self-hosted compiler builds and runs the full test suite'
task test_self_hosted_full: %i[bootstrap build_test_support] do
  sh 'bin/nat --version'
  env = {
    'NAT_BINARY' => 'bin/nat',
  }
  sh env, 'bundle exec ruby test/all.rb'
end

desc 'Test that some representative code runs with the AddressSanitizer enabled'
task test_asan: :build_asan do
  sh 'bin/cuby examples/hello.rb'
  sh 'bin/cuby examples/fib.rb'
  sh 'bin/cuby examples/boardslam.rb 3 5 1'
  %w[
    test/cuby/argument_test.rb
    test/cuby/autoload_test.rb
    test/cuby/backtrace_test.rb
    test/cuby/block_test.rb
    test/cuby/boolean_test.rb
    test/cuby/bootstrap_test.rb
    test/cuby/break_test.rb
    test/cuby/builtin_constants_test.rb
    test/cuby/call_order_test.rb
    test/cuby/caller_test.rb
    test/cuby/class_var_test.rb
    test/cuby/comparable_test.rb
    test/cuby/complex_test.rb
    test/cuby/const_defined_test.rb
    test/cuby/constant_test.rb
    test/cuby/define_method_test.rb
    test/cuby/defined_test.rb
    test/cuby/dup_test.rb
    test/cuby/enumerable_test.rb
    test/cuby/env_test.rb
    test/cuby/equality_test.rb
    test/cuby/eval_test.rb
    test/cuby/fiddle_test.rb
    test/cuby/file_test.rb
    test/cuby/fileutils_test.rb
    test/cuby/fork_test.rb
    test/cuby/freeze_test.rb
    test/cuby/global_test.rb
    test/cuby/if_test.rb
    test/cuby/implicit_conversions_test.rb
    test/cuby/instance_eval_test.rb
    test/cuby/io_test.rb
    test/cuby/ivar_test.rb
    test/cuby/kernel_integer_test.rb
    test/cuby/kernel_test.rb
    test/cuby/lambda_test.rb
    test/cuby/load_path_test.rb
    test/cuby/loop_test.rb
    test/cuby/matchdata_test.rb
    test/cuby/method_test.rb
    test/cuby/method_visibility_test.rb
    test/cuby/module_test.rb
    test/cuby/modulo_test.rb
    test/cuby/namespace_test.rb
    test/cuby/next_test.rb
    test/cuby/nil_test.rb
    test/cuby/numeric_test.rb
    test/cuby/range_test.rb
    test/cuby/rational_test.rb
    test/cuby/rbconfig_test.rb
    test/cuby/regexp_test.rb
    test/cuby/require_test.rb
    test/cuby/return_test.rb
    test/cuby/reverse_each_test.rb
    test/cuby/send_test.rb
    test/cuby/shell_test.rb
    test/cuby/singleton_class_test.rb
    test/cuby/socket_test.rb
    test/cuby/spawn_test.rb
    test/cuby/special_globals_test.rb
    test/cuby/super_test.rb
    test/cuby/symbol_test.rb
    test/cuby/tempfile_test.rb
    test/cuby/yield_test.rb
    test/cuby/zlib_test.rb
  ].each do |path|
    sh "bin/cuby #{path}"
  end
end

task test_all_ruby_spec_nightly: :build do
  unless ENV['CI'] || ENV['DOCKER']
    puts 'This task only runs on CI and/or in Docker, because it is destructive.'
    puts 'Please set CI=true if you really want to run this.'
    exit 1
  end

  sh <<~END
    bundle config set --local with 'run_all_specs'
    bundle install
    git clone https://github.com/ruby/spec /tmp/ruby_spec
    sed -i "1i require 'set' # NATFIXME: No autoload in Cuby\\n" /tmp/ruby_spec/core/enumerable/fixtures/classes.rb
    mv spec/support spec/spec_helper.rb /tmp/ruby_spec
    rm -rf spec
    mv /tmp/ruby_spec spec
  END

  sh 'bundle exec ruby spec/support/nightly_ruby_spec_runner.rb'
end

task output_all_ruby_specs: :build do
  version = RUBY_VERSION.sub(/\.\d+$/, '')
  sh <<~END
    bundle config set --local with 'run_all_specs'
    bundle install
    ruby spec/support/cpp_output_all_specs.rb output/ruby#{version}
  END
end

task :copy_generated_files_to_output do
  version = RUBY_VERSION.sub(/\.\d+$/, '')
  Dir['build/generated/*'].each do |entry|
    if File.directory?(entry)
      mkdir_p entry.sub('build/generated', "output/ruby#{version}")
    end
  end
  Rake::FileList['build/generated/**/*.cpp'].each do |path|
    cp path, path.sub('build/generated', "output/ruby#{version}")
  end
end

desc 'Build the self-hosted version of Cuby at bin/nat'
task bootstrap: [:build, "build/libnat.#{SO_EXT}", 'bin/nat']

desc 'Build MRI C Extension for Prism'
task prism_c_ext: ["build/libprism.#{SO_EXT}", "build/prism/ext/prism/prism.#{DL_EXT}"]

desc 'Show line counts for the project'
task :cloc do
  sh 'cloc include lib src test'
end

desc 'Generate tags file for development'
task :ctags do
  if system('which ctags 2>&1 >/dev/null')
    out = `ctags #{HEADERS + SOURCES} 2>&1`
    puts out unless $?.success?
  else
    puts 'Note: ctags is not available on this system'
  end
end
task tags: :ctags

desc 'Format C++ code with clang-format'
task :format do
  sh 'find include src lib ' \
     "-type f -name '*.?pp' " \
     '! -path src/encoding/casemap.cpp ' \
     '! -path src/encoding/casefold.cpp ' \
     '-exec clang-format -i --style=file {} +'
end

desc 'Show TODO and FIXME comments in the project'
task :todo do
  sh "egrep -r 'FIXME|TODO' src include lib"
end

desc 'Run clang-tidy'
task tidy: %i[build tidy_internal]

desc 'Lint GC visiting code'
task gc_lint: %i[build gc_lint_internal]

def docker_run_flags
  ci = '-i -t' if !ENV['CI'] && $stdout.isatty
  ci = "-e CI=#{ENV['CI']}" if ENV['CI']
  glob = "-e GLOB='#{ENV['GLOB']}'" if ENV['GLOB']
  [
    '-e DOCKER=true',
    ci,
    glob,
  ].compact.join(' ')
end

DEFAULT_HOST_RUBY_VERSION = 'ruby3.3'.freeze
SUPPORTED_HOST_RUBY_VERSIONS = %w[ruby3.1 ruby3.2 ruby3.3].freeze

task :docker_build_gcc do
  sh "docker build -t cuby_gcc_#{ruby_version_string} " \
     "--build-arg IMAGE='ruby:#{ruby_version_number}' " \
     '--build-arg NAT_CXX_FLAGS=-DNAT_GC_GUARD .'
end

task :docker_build_clang do
  sh "docker build -t cuby_clang_#{ruby_version_string} " \
     "--build-arg IMAGE='ruby:#{ruby_version_number}' " \
     '--build-arg NAT_CXX_FLAGS=-DNAT_GC_GUARD ' \
     '--build-arg CC=clang ' \
     '--build-arg CXX=clang++ ' \
     '--build-arg NAT_CXX_FLAGS=-DNAT_GC_GUARD ' \
     '.'
end

task docker_bash: :docker_build_clang do
  sh "docker run -it --rm --entrypoint bash cuby_clang_#{ruby_version_string}"
end

task docker_bash_gcc: :docker_build_gcc do
  sh "docker run -it --rm --entrypoint bash cuby_gcc_#{ruby_version_string}"
end

task docker_bash_lldb: :docker_build_clang do
  sh 'docker run -it --rm ' \
     '--entrypoint bash ' \
     '--cap-add=SYS_PTRACE ' \
     '--security-opt seccomp=unconfined ' \
     "cuby_clang_#{ruby_version_string}"
end

task docker_bash_gdb: :docker_build_gcc do
  sh 'docker run -it --rm ' \
     '--entrypoint bash ' \
     '--cap-add=SYS_PTRACE ' \
     '--security-opt seccomp=unconfined ' \
     '-m 2g ' \
     '--cpus=2 ' \
     "cuby_gcc_#{ruby_version_string}"
end

task docker_test: %i[docker_test_gcc docker_test_clang docker_test_self_hosted docker_test_asan]

task :docker_test_output do
  rm_rf 'output'

  SUPPORTED_HOST_RUBY_VERSIONS.each do |version|
    mkdir_p "output/#{version}"
    ENV['RUBY'] = version
    Rake::Task[:docker_build_clang].invoke
    Rake::Task[:docker_build_clang].reenable 
    sh "docker run #{docker_run_flags} --rm -v $(pwd)/output:/cuby/output " \
       "--entrypoint rake cuby_clang_#{version} " \
       'output_all_ruby_specs ' \
       'copy_generated_files_to_output'
  end

  SUPPORTED_HOST_RUBY_VERSIONS.each_cons(2) do |v1, v2|
    out = `diff -r output/#{v1} output/#{v2} 2>&1`.strip
    unless out.empty?
      puts out
      puts
      raise "Output for #{v1} and #{v2} differs"
    end
  end
end

task docker_test_gcc: :docker_build_gcc do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake cuby_gcc_#{ruby_version_string} test"
end

task docker_test_clang: :docker_build_clang do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake cuby_clang_#{ruby_version_string} test"
end

task docker_test_self_hosted: :docker_build_clang do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake cuby_clang_#{ruby_version_string} test_self_hosted"
end

task docker_test_self_hosted_full: :docker_build_clang do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake cuby_clang_#{ruby_version_string} test_self_hosted_full"
end

task docker_test_asan: :docker_build_clang do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake cuby_clang_#{ruby_version_string} test_asan"
end

task docker_test_all_ruby_spec_nightly: :docker_build_clang do
  sh "docker run #{docker_run_flags} " \
     "-e STATS_API_SECRET=#{(ENV['STATS_API_SECRET'] || '').inspect} " \
     '--rm ' \
     '--entrypoint rake ' \
     "cuby_clang_#{ruby_version_string} test_all_ruby_spec_nightly"
end

task docker_tidy: :docker_build_clang do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake cuby_clang_#{ruby_version_string} tidy"
end

task docker_gc_lint: :docker_build_clang do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake cuby_clang_#{ruby_version_string} gc_lint"
end

def ruby_version_string
  string = ENV['RUBY'] || DEFAULT_HOST_RUBY_VERSION
  raise 'must be in the format rubyX.Y' unless string =~ /^ruby\d\.\d$/
  string
end

def ruby_version_number
  ruby_version_string.sub('ruby', '')
end

if system('which compiledb 2>&1 >/dev/null')
  $compiledb_out = [] 

  def $stderr.puts(str)
    write(str + "\n")
    $compiledb_out << str
  end

  task :write_compile_database do
    if $compiledb_out.any? 
      File.write('build/build.log', $compiledb_out.join("\n")) 
      sh 'compiledb < build/build.log'
    end
  end
else
  task :write_compile_database do
  end
end

STANDARD = 'c++17'.freeze
HEADERS = Rake::FileList['include/**/{*.h,*.hpp}']

PRIMARY_SOURCES = Rake::FileList['src/**/*.{c,cpp}'].exclude('src/main.cpp')
RUBY_SOURCES = Rake::FileList['src/**/*.rb'].exclude('**/extconf.rb')
SPECIAL_SOURCES = Rake::FileList['build/generated/platform.cpp', 'build/generated/bindings.cpp']
SOURCES = PRIMARY_SOURCES + RUBY_SOURCES + SPECIAL_SOURCES

PRIMARY_OBJECT_FILES = PRIMARY_SOURCES.sub('src/', 'build/').pathmap('%p.o')
RUBY_OBJECT_FILES = RUBY_SOURCES.pathmap('build/generated/%{^src/,}p.o')
SPECIAL_OBJECT_FILES = SPECIAL_SOURCES.pathmap('%p.o')
OBJECT_FILES = PRIMARY_OBJECT_FILES + RUBY_OBJECT_FILES + SPECIAL_OBJECT_FILES

require 'tempfile'

task(:set_build_debug) do
  ENV['BUILD'] = 'debug'
  File.write('.build', 'debug')
end

task(:set_build_asan) do
  ENV['BUILD'] = 'asan'
  File.write('.build', 'asan')
end

task(:set_build_release) do
  ENV['BUILD'] = 'release'
  File.write('.build', 'release')
end

task libcuby: [
  :update_submodules,
  :bundle_install,
  :build_dir,
  'build/zlib/libz.a',
  'build/onigmo/lib/libonigmo.a',
  'build/libprism.a',
  "build/libprism.#{SO_EXT}",
  'build/generated/numbers.rb',
  :primary_objects,
  :ruby_objects,
  :special_objects,
  'build/libcuby.a',
  "build/libcuby_base.#{DL_EXT}",
  :write_compile_database,
]

task :build_dir do
  mkdir_p 'build/generated' unless File.exist?('build/generated')
end

task build_test_support: [
  "build/libnat.#{SO_EXT}",
  "build/test/support/ffi_stubs.#{SO_EXT}",
]

multitask primary_objects: PRIMARY_OBJECT_FILES
multitask ruby_objects: RUBY_OBJECT_FILES
multitask special_objects: SPECIAL_OBJECT_FILES

file 'build/libcuby.a' => %w[
  build/libcuby_base.a
  build/onigmo/lib/libonigmo.a
] do |t|
  if RUBY_PLATFORM =~ /darwin/
    sh "libtool -static -o #{t.name} #{t.sources.join(' ')}"
  else
    ar_script = ["create #{t.name}"]
    t.sources.each { |source| ar_script << "addlib #{source}" }
    ar_script << 'save'
    ENV['AR_SCRIPT'] = ar_script.join("\n")
    sh 'echo "$AR_SCRIPT" | ar -M'
  end
end

file 'build/libcuby_base.a' => OBJECT_FILES + HEADERS do |t|
  sh "ar rcs #{t.name} #{OBJECT_FILES}"
end

file "build/libcuby_base.#{DL_EXT}" => OBJECT_FILES + HEADERS do |t|
  sh "#{cxx} -shared -fPIC -rdynamic -Wl,-undefined,dynamic_lookup -o #{t.name} #{OBJECT_FILES}"
end

file 'build/onigmo/lib/libonigmo.a' do
  build_dir = File.expand_path('build/onigmo', __dir__)
  patch_path = File.expand_path('ext/onigmo.patch', __dir__)
  rm_rf build_dir
  cp_r 'ext/onigmo', build_dir
  sh <<-SH
    cd 
    sh autogen.sh && \
    ./configure --with-pic --prefix 
    git apply
    make -j 4 && \
    make install
  SH
end

file 'build/zlib/libz.a' do
  build_dir = File.expand_path('build/zlib', __dir__)
  rm_rf build_dir
  cp_r 'ext/zlib', build_dir
  sh <<-SH
    cd 
    ./configure && \
    make -j 4
  SH
end

file 'build/generated/numbers.rb' do |t|
  f1 = Tempfile.new(%w[numbers .cpp])
  f2 = Tempfile.create('numbers')
  f2.close
  begin
    f1.puts '#include <stdio.h>'
    f1.puts '#include "cuby/constants.hpp"'
    f1.puts 'int main() {'
    f1.puts '  printf("NAT_MAX_FIXNUM = %lli\n", NAT_MAX_FIXNUM);'
    f1.puts '  printf("NAT_MIN_FIXNUM = %lli\n", NAT_MIN_FIXNUM);'
    f1.puts '}'
    f1.close
    sh "#{cxx} #{cxx_flags.join(' ')} -std=#{STANDARD} -o #{f2.path} #{f1.path}"
    sh "#{f2.path} > #{t.name}"
  ensure
    File.unlink(f1.path)
    File.unlink(f2.path)
  end
end

file 'build/generated/platform.cpp' => OBJECT_FILES - ['build/generated/platform.cpp.o'] do |t|
  git_revision = `git show --pretty=%H --quiet`.chomp
  File.write(t.name, <<~END)
    #include "cuby.hpp"
    const char *Cuby::ruby_platform = #{RUBY_PLATFORM.inspect};
    const char *Cuby::ruby_release_date = "#{Time.now.strftime('%Y-%m-%d')}";
    const char *Cuby::ruby_revision = "#{git_revision}";
  END
end

file 'build/generated/platform.cpp.o' => 'build/generated/platform.cpp' do |t|
  sh "#{cxx} #{cxx_flags.join(' ')} -std=#{STANDARD} -c -o #{t.name} #{t.name.pathmap('%d/%n')}"
end

file 'build/generated/bindings.cpp.o' => ['lib/cuby/compiler/binding_gen.rb'] + HEADERS do |t|
  sh "ruby lib/cuby/compiler/binding_gen.rb > #{t.name.pathmap('%d/%n')}"
  sh "#{cxx} #{cxx_flags.join(' ')} -std=#{STANDARD} -c -o #{t.name} #{t.name.pathmap('%d/%n')}"
end

file 'bin/nat' => OBJECT_FILES + ['bin/cuby'] do
  sh 'bin/cuby -c bin/nat bin/cuby'
end

file "build/libnat.#{SO_EXT}" => SOURCES + ['lib/cuby/api.cpp', 'build/libcuby.a'] do |t|
  sh 'bin/cuby --write-obj build/libnat.rb.cpp lib/cuby.rb'
  if system('pkg-config --exists libffi')
    flags = `pkg-config --cflags --libs libffi`.chomp
  end
  sh "#{cxx} #{cxx_flags.join(' ')} #{flags} -std=#{STANDARD} " \
     '-DNAT_OBJECT_FILE -shared -fPIC -rdynamic ' \
     '-Wl,-undefined,dynamic_lookup ' \
     "-o #{t.name} build/libnat.rb.cpp build/libcuby.a"
end

rule '.c.o' => 'src/%n' do |t|
  sh "#{cc} -I include -g -fPIC -c -o #{t.name} #{t.source}"
end

rule '.cpp.o' => ['src/%{build/,}X'] + HEADERS do |t|
  subdir = File.split(t.name).first
  mkdir_p subdir unless File.exist?(subdir)
  sh "#{cxx} #{cxx_flags.join(' ')} -std=#{STANDARD} -c -o #{t.name} #{t.source}"
end

rule '.rb.o' => ['.rb.cpp'] + HEADERS do |t|
  sh "#{cxx} #{cxx_flags.join(' ')} -std=#{STANDARD} -c -o #{t.name} #{t.source}"
end

rule '.rb.cpp' => ['src/%{build\/generated/,}X'] do |t|
  subdir = File.split(t.name).first
  mkdir_p subdir unless File.exist?(subdir)
  sh "bin/cuby --write-obj #{t.name} #{t.source}"
end

file "build/libprism.#{SO_EXT}" => ['build/libprism.a']

file 'build/libprism.a' => ["build/prism/ext/prism/prism.#{DL_EXT}"] do
  build_dir = File.expand_path('build/prism', __dir__)
  cp "#{build_dir}/build/libprism.a", File.expand_path('build', __dir__)
  cp "#{build_dir}/build/libprism.#{SO_EXT}", File.expand_path('build', __dir__)
end

file "build/prism/ext/prism/prism.#{DL_EXT}" => Rake::FileList['ext/prism/**/*.{h,c,rb}'] do
  build_dir = File.expand_path('build/prism', __dir__)

  rm_rf build_dir
  cp_r 'ext/prism', build_dir

  sh <<-SH
    cd  
    PRISM_FFI_BACKEND=true rake templates
    cd  
    make && \
    cd ext/prism && \
    ruby extconf.rb && \
    make -j 4
  SH
end

file "build/test/support/ffi_stubs.#{SO_EXT}" => 'test/support/ffi_stubs.c' do |t|
  mkdir_p 'build/test/support'
  sh "#{cc} -shared -fPIC -rdynamic -Wl,-undefined,dynamic_lookup -o #{t.name} #{t.source}"
end

task :tidy_internal do
  sh "clang-tidy --warnings-as-errors='*' #{PRIMARY_SOURCES.exclude('src/dtoa.c')}"
end

task :gc_lint_internal do
  sh 'ruby test/gc_lint.rb'
end

task :bundle_install do
  sh 'bundle check || bundle install'
end

task :update_submodules do
  unless ENV['SKIP_SUBMODULE_UPDATE']
    sh 'git submodule update --init --recursive'
  end
end

def ccache_exists?
  return @ccache_exists if defined?(@ccache_exists)
  @ccache_exists = system('which ccache 2>&1 > /dev/null')
end

def cc
  @cc ||=
    if ENV['CC']
      ENV['CC']
    elsif ccache_exists?
      'ccache cc'
    else
      'cc'
    end
end

def cxx
  @cxx ||=
    if ENV['CXX']
      ENV['CXX']
    elsif ccache_exists?
      'ccache c++'
    else
      'c++'
    end
end

def cxx_flags
  base_flags =
    case ENV['BUILD']
    when 'release'
      Cuby::Compiler::Flags::RELEASE_FLAGS
    when 'asan'
      Cuby::Compiler::Flags::ASAN_FLAGS
    else
      Cuby::Compiler::Flags::DEBUG_FLAGS
    end
  base_flags += ['-fPIC']  
  if RUBY_PLATFORM =~ /darwin/
    base_flags += ['-D_DARWIN_C_SOURCE']
  end
  user_flags = Array(ENV['NAT_CXX_FLAGS'])
  base_flags + user_flags + include_paths.map { |path| "-I #{path}" }
end

def include_paths
  [
    File.expand_path('include', __dir__),
    File.expand_path('ext/tm/include', __dir__),
    File.expand_path('ext/minicoro', __dir__),
    File.expand_path('build', __dir__),
    File.expand_path('build/onigmo/include', __dir__),
    File.expand_path('build/prism/include', __dir__),
  ]
end