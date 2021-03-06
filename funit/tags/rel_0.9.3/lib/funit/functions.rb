require 'erb'

module Funit

  TEST_RUNNER = ERB.new %q{
    ! TestRunner.f90 - runs fUnit test suites
    !
    ! <%= File.basename $0 %> generated this file on <%= Time.now %>.

    program TestRunner
      <%= test_suites.inject('') { |result,test_suite| result << "\n  use #{test_suite}_fun" } %>

      implicit none

      integer :: numTests, numAsserts, numAssertsTested, numFailures

      <% test_suites.each do |ts| %>
      print *, ""
      print *, "<%= ts %> test suite:"
      call test_<%= ts %> &
        ( numTests, numAsserts, numAssertsTested, numFailures )
      print *, "Passed", numAssertsTested, "of", numAsserts, &
               "possible asserts comprising",                &
               numTests-numFailures, "of", numTests, "tests."
      <% end %>
      print *, ""

    end program TestRunner
    }.gsub(/^/,'    '), nil, '<>' # turn off newlines due to <%%>

  def requested_modules(module_names)
    if module_names.empty?
      module_names = Dir["*.fun"].each{ |mod| mod.chomp! ".fun" }
    end
    module_names
  end

  def funit_exists?(module_name)
    File.exists? "#{module_name}.fun"
  end

  def parse_command_line

    module_names = requested_modules(ARGV)

    if module_names.empty?
      raise "   *Error: no test suites found in this directory"
    end

    module_names.each do |mod|
      unless funit_exists?(mod) 
        error_message = <<-FUNIT_DOES_NOT_EXIST
 Error: could not find test suite #{mod}.fun
 Test suites available in this directory:
 #{requested_modules([]).join(' ')}

 Usage: #{File.basename $0} [test names (w/o .fun suffix)]
        FUNIT_DOES_NOT_EXIST
        raise error_message
      end
    end

  end

  def write_test_runner test_suites
    File.open("TestRunner.f90", "w") do |file|
      file.puts TEST_RUNNER.result(binding)
    end
  end

  def syntax_error( message, test_suite )
    raise "\n   *Error: #{message} [#{test_suite}.fun:#$.]\n\n"
  end

  def warning( message, test_suite )
    $stderr.puts "\n *Warning: #{message} [#{test_suite}.fun:#$.]"
  end

  def compile_tests test_suites
    puts "computing dependencies"
    dependencies = Fortran::Dependencies.new
    puts "locating associated source files and sorting for compilation"
    required_sources = dependencies.required_source_files('TestRunner.f90')

    puts compile = "#{ENV['FC']} #{ENV['FCFLAGS']} -o TestRunner #{required_sources.join(' ')}"

    raise "Compile failed." unless system compile
  end

end

#--
# Copyright 2006-2007 United States Government as represented by
# NASA Langley Research Center. No copyright is claimed in
# the United States under Title 17, U.S. Code. All Other Rights
# Reserved.
#
# This file is governed by the NASA Open Source Agreement.
# See License.txt for details.
#++
