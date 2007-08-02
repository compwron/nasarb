require 'test/unit'
require 'uq4sim/distributions'
require 'uq4sim/statistics'

# For real tests, see SAND2006-1706,
# http://gaston.sandia.gov/cfupload/ccim_pubs_prod/V&VLHS05.pdf

class Array # mixin statistical functions
  include Uq4sim::Statistics
end

class TestUniformDistribution < Test::Unit::TestCase

  include Uq4sim

  def setup
    srand 1234
  end

  def test_nominal_range
    100.times do |i|
      sample = randu
      assert( (-0.5..0.5).include?(sample),
              "#{i}: #{sample} not in [-0.5,0.5]" )
    end
  end

  def test_specified_halfwidth
    100.times do |i|
      sample = randu(1)
      assert( (-1..1).include?(sample),
              "#{i}: #{sample} not in [-1,1]" )
    end
  end

  def test_specified_fractional_width_range
    100.times do |i|
      sample = randu(0.4)
      assert( (-0.4..0.4).include?(sample),
              "#{i}: #{sample} not in [-0.4,.4]" )
    end
  end

  def test_statistics
    samples = []
    1000.times{ samples << randu }
    assert_in_delta( 0.0, samples.mean, 0.01, "mean" )
    assert_in_delta( 0.0, samples.median, 0.05, "median" )
    assert_in_delta( 0.29, samples.standard_deviation, 0.005, "sigma" )
    assert_in_delta( 0.0, samples.skewness, 0.1, "skewness" )
    assert_in_delta( 1.8, samples.kurtosis, 0.05, "kurtosis" )
  end

end

class TestNormalDistribution < Test::Unit::TestCase

  include Uq4sim

  def setup
    srand 1234
  end

  def test_nominal_statistics
    samples = []
    1000.times{ samples << randn }
    assert_in_delta( 0.0, samples.mean, 0.05, "mean" )
    assert_in_delta( 0.0, samples.median, 0.1, "median" )
    assert_in_delta( 1.0, samples.standard_deviation, 0.05, "sigma" )
    assert_in_delta( 0.0, samples.skewness, 0.1, "skewness" )
    assert_in_delta( 3.0, samples.kurtosis, 0.1, "kurtosis" )
  end

  def test_specified_sigma_statistics
    samples = []
    1000.times{ samples << randn(0.2) }
    assert_in_delta( 0.0, samples.mean, 0.05, "mean" )
    assert_in_delta( 0.0, samples.median, 0.05, "median" )
    assert_in_delta( 0.2, samples.standard_deviation, 0.05, "sigma" )
    assert_in_delta( 0.0, samples.skewness, 0.1, "skewness" )
    assert_in_delta( 3.0, samples.kurtosis, 0.1, "kurtosis" )
  end

end

class TestInverseNormalDistribution < Test::Unit::TestCase

  include Uq4sim

  def test_tails_and_midrange_with_known_values
    assert_in_delta( -4,      inverse_normal_cdf(0.00003), 0.05 )
    assert_in_delta( -3,      inverse_normal_cdf(0.0012),  0.05 )
    assert_in_delta( -2,      inverse_normal_cdf(0.025),   0.05 )
    assert_in_delta( -1,      inverse_normal_cdf(0.16),    0.05 )
    assert_in_delta( -0.6745, inverse_normal_cdf(0.25), 0.00005 )
    assert_equal(     0,      inverse_normal_cdf(0.5) )
    assert_in_delta(  0.6745, inverse_normal_cdf(0.75), 0.00005 )
    assert_in_delta(  1,      inverse_normal_cdf(0.84),    0.05 )
    assert_in_delta(  2,      inverse_normal_cdf(0.975),   0.05 )
    assert_in_delta(  3,      inverse_normal_cdf(0.9988),  0.05 )
    assert_in_delta(  4,      inverse_normal_cdf(0.99997), 0.05 )
  end

  def test_raises_exception_when_p_is_out_of_range
    assert_raise( RuntimeError ){ inverse_normal_cdf(-0.1) }
    assert_raise( RuntimeError ){ inverse_normal_cdf(0) }
    assert_raise( RuntimeError ){ inverse_normal_cdf(1) }
    assert_raise( RuntimeError ){ inverse_normal_cdf(1.1) }
  end

end