require 'test/unit'
require 'funit'
require 'ftools' # FIXME: migrate to fileutils

class TestFunit < Test::Unit::TestCase

  include Funit # FIXME
  include Funit::Assertions # FIXME

  def setup
    File.rm_f(*Dir["dummyunit*"])
    File.rm_f(*Dir["unit*"])
    File.rm_f(*Dir["ydsbe*"])
    File.rm_f(*Dir["lmzd*"])
    File.rm_f(*Dir["ldfdl*"])
    File.rm_f(*Dir["ydsbe*"])
    File.rm_f(*Dir["TestRunner*"])
    File.rm_f(*Dir["a.out"])
  end

  def teardown
    File.rm_f(*Dir["dummyunit*"])
    File.rm_f(*Dir["unit*"])
    File.rm_f(*Dir["ydsbe*"])
    File.rm_f(*Dir["lmzd*"])
    File.rm_f(*Dir["ldfdl*"])
    File.rm_f(*Dir["ydsbe*"])
    File.rm_f(*Dir["TestRunner*"])
    File.rm_f(*Dir["a.out"])
  end

  def test_main_driver_compiles
    write_test_runner []
    assert File.exists?("TestRunner.f90")
    assert system("#{ENV['FC']} TestRunner.f90")
    assert File.exists?("a.out")
  end

  def test_is_equal
    @suite_name = "dummy"
    @test_name = "dummy"
    @line_number = "dummy"
    isequal("IsEqual(1.0,m(1,1))")
    assert_equal '.not.(1.0==m(1,1))', @condition
  end 

  def test_is_real_equal
    @suite_name = "dummy"
    @test_name = "dummy"
    @line_number = "dummy"
    isrealequal("IsRealEqual(a,b)")
    ans = <<-EOF
.not.(a+2*spacing(real(a)).ge.b &
             .and.a-2*spacing(real(a)).le.b)
    EOF
    assert_equal ans.chomp, @condition
    assert_equal '"b (",b,") is not",a,"within",2*spacing(real(a))', @message
    isrealequal("IsRealEqual(1.0,m(1,1))")
    ans = <<-EOF
.not.(1.0+2*spacing(real(1.0)).ge.m(1,1) &
             .and.1.0-2*spacing(real(1.0)).le.m(1,1))
    EOF
    assert_equal ans.chomp, @condition
  end

  def test_handles_dependency
    File.open('unit.f90','w') do |f|
      f.printf "module unit\n  use unita, only : a\nend module unit\n"
    end
    File.open('unita.f90','w') do |f|
      f.printf "module unita\n  integer :: a = 5\nend module unita\n"
    end
    File.open('unit.fun','w') do |f|
      f.printf "beginTest a_gets_set\n  IsEqual(5, a)\nendTest\n"
    end
    assert_nothing_raised{run_tests}
  end

  def test_embedded_dependencies
    File.open('unit.f90','w') do |f|
      f.printf "module unit\n  use unita, only : a\nend module unit\n"
    end
    File.open('unita.f90','w') do |f|
      f.printf "module unita\n  use unitb, only : b \n  integer :: a = b\nend module unita\n"
    end
    File.open('unitb.f90','w') do |f|
      f.printf "module unitb\n  integer,parameter :: b = 5\nend module unitb\n"
    end
    File.open('unit.fun','w') do |f|
      f.printf "beginTest a_gets_set\n  IsEqual(5, a)\nendTest\n"
    end
    assert_nothing_raised{run_tests}
 end

  def test_requested_modules
    assert_equal ["asdfga"], requested_modules(["asdfga"])
    assert_equal ["asd","fga"], requested_modules(["asd","fga"])
    assert requested_modules([]).empty?
    modules = %w[ldfdl lmzd]
    funits = modules.map{|f| f+'.fun'}.join(' ')
    system "touch "+funits
    assert_equal modules, requested_modules([])
  end

  def test_funit_exists_method
    module_name = "ydsbe"
    File.rm_f(module_name+".fun")
    assert_equal false, funit_exists?(module_name)
    system "touch "+module_name+".fun"
    assert funit_exists?(module_name)
  end

end
