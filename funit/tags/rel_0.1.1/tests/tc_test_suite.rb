#! /usr/bin/env ruby

$:.unshift File.join( File.dirname(__FILE__), '..', 'lib' )

require 'test/unit'
require 'funit/test_suite'
require 'funit/assertions'

class TestTestSuite < Test::Unit::TestCase

  def setup
    File.rm_f(*Dir["dummyf90test*"])
  end 

  def teardown
    File.rm_f(*Dir["dummyf90test*"])
  end 

  def test_nonexistent_funit_file_is_not_created
    Funit::TestSuite.new 'dummyf90test'
    assert !File.exists?("dummyf90test.fun")
    assert !File.exists?("dummyf90test_fun.f90")
  end

  def create_funit_file funit_contents
    File.open('dummyf90test.f90','w') do |f|
      f.puts "module dummyf90test\nend module dummyf90test"
    end
    File.open('dummyf90test.fun','w') do |f|
      f.puts funit_contents
    end
  end

  @@compileCommand = "#{Funit::Compiler.new.name} -c dummyf90test.f90 dummyf90test_fun.f90"

  def test_bare_minimum_funit_file_compiles
    create_funit_file ""
    Funit::TestSuite.new 'dummyf90test'
    assert system(@@compileCommand)
  end

  def test_module_variables_allowed
    create_funit_file "integer :: a"
    Funit::TestSuite.new 'dummyf90test'
    assert system(@@compileCommand)
  end

  def test_blank_setup_compiles
    create_funit_file "beginSetup\nendSetup"
    Funit::TestSuite.new 'dummyf90test'
    assert system(@@compileCommand)
  end

  def test_blank_test_gives_warning
    create_funit_file "beginTest bob\nendTest"
    Funit::TestSuite.new 'dummyf90test'
    assert system(@@compileCommand)
  end

  def test_single_assert_test_compiles
    create_funit_file "beginTest assertTrue\nIsTrue(.true.)\nendTest"
    Funit::TestSuite.new 'dummyf90test'
    assert system(@@compileCommand)
  end

  def test_matrix_assert_compiles
    create_funit_file <<-MATRIX
 beginTest assertTrue
  integer :: a(2,2)
  a = 1
  IsEqual(a(1,1),1)
 endTest
    MATRIX
    Funit::TestSuite.new 'dummyf90test'
    assert system(@@compileCommand)
  end

  def test_simple_real_equals_assert_works
    create_funit_file <<-REALEQUALS
 beginTest assert_equals
  real :: real_var
  real_var = 1.0
  IsRealEqual(real_var,1.0)
 endTest
    REALEQUALS
    Funit::TestSuite.new 'dummyf90test'
    assert system(@@compileCommand)
  end

  def test_real_equals_assert_works_with_function
    create_funit_file <<-REQUALSFUNC
 beginTest assert_equals_for_function
  IsRealEqual(balance(0.0,0.0),0.0)
 endTest
 function balance( left, right)
  real :: balance
  real, intent(in) :: left, right
  balance = 0.5*(left+right)
 end function balance
    REQUALSFUNC
    Funit::TestSuite.new 'dummyf90test'
    assert system(@@compileCommand)
  end

  def test_ignore_commented_test
    create_funit_file "XbeginTest bob\nendTest"
    Funit::TestSuite.new 'dummyf90test'
    assert_no_match( /Testbob/i, IO.readlines('dummyf90test_fun.f90').join )
  end

end
