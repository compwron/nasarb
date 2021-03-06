require 'funit/assertions'
require 'funit/functions'
require 'ftools' # FIXME: use fileutils

module Funit
  
  include Assertions # FIXME

  ##
  # Create testsuite wrapper code

  class TestSuite < File

    ASSERTION_PATTERN = /Is(RealEqual|False|True|EqualWithin|Equal)\(.*\)/i
    KEYWORDS = /(begin|end)(Setup|Teardown|Test)|Is(RealEqual|Equal|False|True|EqualWithin)\(.*\)/i
    COMMENT_LINE = /^\s*!/
    
    include Funit #FIXME

    def initialize suite_name
      @line_number = 'blank'
      @suite_name = suite_name
      return nil unless funit_exists?(suite_name)
      File.delete(suite_name+"_fun.f90") if File.exists?(suite_name+"_fun.f90")
      super(suite_name+"_fun.f90","w")
      @tests, @setup, @teardown = [], [], []
      top_wrapper
      expand
      close
    end

    def top_wrapper
      puts <<-TOP
! #{@suite_name}_fun.f90 - a unit test suite for #{@suite_name}.f90
!
! #{File.basename $0} generated this file from #{@suite_name}.fun
! at #{Time.now}

module #{@suite_name}_fun

 use #{@suite_name}

 implicit none

 logical :: noAssertFailed

 public :: test_#@suite_name

 private

 integer :: numTests          = 0
 integer :: numAsserts        = 0
 integer :: numAssertsTested  = 0
 integer :: numFailures       = 0

      TOP
    end

    def expand
      funit_file = @suite_name+".fun"
      $stderr.print "expanding #{funit_file}..."
   
      funit_contents = IO.readlines(funit_file)
      @funit_total_lines = funit_contents.length

      while (line = funit_contents.shift) && line !~ KEYWORDS
        puts line
      end

      funit_contents.unshift line

      puts " contains\n\n"

      while (line = funit_contents.shift)
        case line
        when COMMENT_LINE
          puts line
        when /beginSetup/i
          add_to_setup funit_contents
        when /beginTeardown/i
          add_to_teardown funit_contents
        when /XbeginTest\s+(\w+)/i
          ignore_test($1,funit_contents)
        when /beginTest\s+(\w+)/i
          a_test($1,funit_contents)
        when /beginTest/i
          syntax_error "no name given for beginTest", @suite_name
        when /end(Setup|Teardown|Test)/i
          syntax_error "no matching begin#$1 for an #$&", @suite_name
        when ASSERTION_PATTERN
          syntax_error "#$1 assert not in a test block", @suite_name
        else
          puts line
        end
      end
      $stderr.puts "done."
    end

    def add_to_setup funit_contents
      while (line = funit_contents.shift) && line !~ /endSetup/i
        @setup.push line
      end
    end

    def add_to_teardown funit_contents
      while (line = funit_contents.shift) && line !~ /endTeardown/i
        @teardown.push line
      end
    end

    def ignore_test test_name, funit_contents
      warning("Ignoring test: #{test_name}", @suite_name)
      line = funit_contents.shift while line !~ /endTest/i
    end

    def a_test test_name, funit_contents
      @test_name = test_name
      @tests.push test_name
      syntax_error("test name #@test_name not unique",@suite_name) if (@tests.uniq!)

      puts " subroutine #{test_name}\n\n"

      num_of_asserts = 0
  
      while (line = funit_contents.shift) && line !~ /endTest/i
        case line
        when COMMENT_LINE
          puts line
        when /Is(RealEqual|False|True|EqualWithin|Equal)/i
          @line_number = @funit_total_lines - funit_contents.length
          num_of_asserts += 1
          puts send( $&.downcase!, line )
        else
          puts line
        end
      end
      warning("no asserts in test", @suite_name) if num_of_asserts == 0

      puts "\n  numTests = numTests + 1\n\n"
      puts " end subroutine #{test_name}\n\n"
    end

    def close
      puts "\n subroutine Setup"
      puts @setup
      puts "  noAssertFailed = .true."
      puts " end subroutine Setup\n\n"

      puts "\n subroutine Teardown"
      puts @teardown
      puts " end subroutine Teardown\n\n"

      puts <<-NEXTONE

 subroutine test_#{@suite_name}( nTests, nAsserts, nAssertsTested, nFailures )

  integer :: nTests
  integer :: nAsserts
  integer :: nAssertsTested
  integer :: nFailures

  continue
      NEXTONE

      @tests.each do |test_name|
        puts "\n  call Setup"
        puts "  call #{test_name}"
        puts "  call Teardown"
      end

      puts <<-LASTONE

  nTests          = numTests
  nAsserts        = numAsserts
  nAssertsTested  = numAssertsTested
  nFailures       = numFailures

 end subroutine test_#{@suite_name}

end module #{@suite_name}_fun
      LASTONE
      super
    end

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