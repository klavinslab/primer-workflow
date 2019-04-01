# frozen_string_literal: true

# Defines a superclass of sample objects to encapsulate Aquarium Sample objects.
class AbstractSample
  attr_accessor :item, :sample, :properties

  # Instantiates a new AbstractSample.
  #
  # @param sample [Sample] Sample
  # @param expected_sample_type [String] the name of the expected sample type
  # @raises [WrongSampleTypeError] if the type of the sample is not
  def initialize(sample:, expected_sample_type:)
    @sample = sample
    @properties = sample.properties

    return if type?(expected_sample_type)

    msg = "Sample #{sample.id}, #{sample.sample_type.name}, " \
          "is not a #{expected_sample_type}."
    raise WrongSampleTypeError.new(
      msg: msg, sample: sample, expected_type: expected_sample_type
    )
  end

  # Test whether this Sample has the given sample type.
  #
  # @param sample_type [String] the name of the sample type
  # @return [Boolean] true if the sample has the named type, and false otherwise.
  def type?(expected_sample_type)
    sample && sample.sample_type.name == expected_sample_type
  end

  # The name of the sample.
  #
  # @return [String] the name of the sample
  def name
    sample.name
  end

  # Fetches a property of this sample by name.
  #
  # @param property [String] the name of the property
  # @return [Object] the value of the named property for this sample
  def fetch(property)
    properties.fetch(property)
  end
end

# Exception class for an sample with the wrong sample type.
#
# @attr_reader [Sample] sample  the sample object
# @attr_reader [String] expected_type  the name of the expected sample type
class WrongSampleTypeError < StandardError
  attr_reader :sample, :expected_type

  def initialize(msg: 'Sample is not the expected type', sample:, expected_type:)
    @sample = sample
    @expected_type = expected_type
    super(msg)
  end
end
