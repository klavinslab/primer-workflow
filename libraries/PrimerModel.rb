# frozen_string_literal: true

# Defines the Primer class with methods to manage the properties of primers,
# such as sequence, length, priming site, etc.
module PrimerModel
  # Represents a primer object for use in protocols.
  # Wraps an `Item` with sample type `'Primer'`.
  #
  class Primer
    THIS_SAMPLE_TYPE = 'Primer'
    OVERHANG_SEQUENCE = 'Overhang Sequence'
    ANNEAL_SEQUENCE = 'Anneal Sequence'
    T_ANNEAL = 'T Anneal'

    attr_accessor :item, :sample, :properties

    # Instantiates a new Primer.
    #
    # @param sample [Sample] Sample of SampleType `'Primer'`
    # @return [Primer]  an object for the given sample
    # @raise [WrongSampleTypeError] if the sample type is not `'Primer'`
    def initialize(sample:)
      @sample = sample

      unless Primer.is_primer?(sample)
        msg = "Sample #{sample.id}, #{sample.sample_type.name}, is not a #{THIS_SAMPLE_TYPE}."
        raise WrongSampleTypeError, msg
      end

      @properties = sample.properties
      @item = nil
    end

    # Creates a Primer from the given item.
    #
    # @param item [Item] an Item with `'Primer'` sample type
    def self.from_item(item)
      op = Primer.new(sample: item.sample)
      op.set_item(item)
      op
    end

    # Associates an item with this `Primer` object
    #
    # @param item [Item] the item to associate to this object
    # @raise [WrongSampleTypeError] if the item sample type is not `'Primer'`
    def set_item(item)
      unless Primer.is_primer?(item.sample)
        msg = "Expected item with sample type #{THIS_SAMPLE_TYPE}. " \
              "Got item #{item.id} with sample type #{item.sample.sample_type}"
        raise WrongSampleTypeError, msg
      end

      self.item = item
    end

    # Indicate whether a Sample is an Primer
    #
    # @param sample [Sample] the sample 
    # @return [Boolean] true if the sample is a primer, false otherwise
    def self.is_primer?(sample)
      sample && sample.sample_type.name == THIS_SAMPLE_TYPE
    end

    # Return the overhang sequence for this Primer
    #
    # @return [String] the overhang sequence for this Primer
    def overhang_sequence
      properties.fetch(OVERHANG_SEQUENCE).strip
    end

    # Return the anneal sequence for this Primer
    #
    # @return [String] the anneal sequence for this Primer
    def anneal_sequence
      properties.fetch(ANNEAL_SEQUENCE).strip
    end

    # Return the sequence for this Primer determined as the composition of the
    # overhang and anneal sequences.
    #
    # @return the composition of the overhang and anneal sequences of this Primer
    def sequence
      overhang_sequence + anneal_sequence
    end

    # Return the length of the sequence of this Primer.
    #
    # @return the length of the sequence of this Primer
    def length
      sequence.length
    end

    # Return the annealing temperature of this Primer.
    #
    # @return the annealing temperature
    def t_anneal
      properties.fetch(T_ANNEAL)
    end

    # Computes the priming site for this Primer.
    #
    # @return [String] the substring for the priming site
    def detect_priming_site(template:, min_length: 16, require_perfect: 3, allow_mismatch: 1)
      query = last_n(require_perfect)
      matches = scan(template, query)
      matches.delete_if { |m| m.offset(0)[1] < min_length }
      return if matches.blank?

      i = 0
      loop do
        break if matches.length <= 1
        i += 1
        query = last_n(require_perfect + i)
        matches.keep_if { |m| expand_match(template, m, i) =~ /#{query}/i }
      end

      _, stop = matches[0].offset(0)
      return unless template[0..stop] =~ /#{last_n(stop)}/i
      [0, stop]
    end

    # Return the last n bases of the primer sequence.
    #
    # @return [String] the last n bases of the primer sequence
    def last_n(n)
      sequence[-n..-1]
    end

    # 
    def scan(template, pat)
      template.to_enum(:scan, /#{pat}/i).map { Regexp.last_match }
    end

    def expand_match(template, match, i)
      start, stop = match.offset(0)
      template[start - i..stop]
    end
  end
end
