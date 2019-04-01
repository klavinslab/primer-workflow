needs 'Sample Models/AbstractSample'

# frozen_string_literal: true

# Defines the Primer class with methods to manage the properties of primers,
# such as sequence, length, priming site, etc.
class Primer < AbstractSample
  THIS_SAMPLE_TYPE = 'Primer'
  OVERHANG_SEQUENCE = 'Overhang Sequence'
  ANNEAL_SEQUENCE = 'Anneal Sequence'
  T_ANNEAL = 'T Anneal'
  private_constant(
    :THIS_SAMPLE_TYPE, :OVERHANG_SEQUENCE, :ANNEAL_SEQUENCE, :T_ANNEAL
  )

  # Instantiates a new Primer.
  #
  # @param sample [Sample] Sample of SampleType "Primer"
  # @return [Primer]
  def initialize(sample:)
    super(sample: sample, expected_sample_type: THIS_SAMPLE_TYPE)
  end

  # Instantiates a new Primer from an Item.
  #
  # @param item [Item] Item of a Sample of SampleType "Primer"
  # @return [Primer]
  def self.from_item(item)
    Primer.new(sample: item.sample)
  end

  # Return the overhang sequence for this Primer.
  #
  # @return [String] the overhang sequence for this Primer
  def overhang_sequence
    fetch(OVERHANG_SEQUENCE).strip
  end

  # Return the anneal sequence for this Primer.
  #
  # @return [String] the anneal sequence for this Primer
  def anneal_sequence
    fetch(ANNEAL_SEQUENCE).strip
  end

  # Return the sequence for this Primer determined as the composition of the
  # overhang and anneal sequences.
  #
  # @return the composition of the overhang and anneal sequences of this Primer
  def sequence
    overhang_sequence + anneal_sequence
  end

  # Return the length of the primer primer sequence in nt.
  #
  # @return [FixNum] the length of the sequence of this primer
  def length
    sequence.length
  end

  # The annealing temperature of the primer
  #
  # @note This is the temperature as it is entered into the database.
  #       It is not calculated and may be inaccurate depending on the template.
  # @return [FixNum] the annealing temperature
  def t_anneal
    fetch(T_ANNEAL)
  end

  # Finds binding sites for a set of primers on a set of templates
  #
  # @param primers [Array<Primer>] the primers
  # @param sites [Array<String>] the templates to be scanned
  # @return [Array<Hash>]
  def self.get_bindings(primers:, sites:)
    bindings = []
    primers.each do |primer|
      sites.each do |site|
        offset = primer.detect_priming_site(template: site)
        next if offset.blank?
        added_length = primer.sequence.length - offset[1]

        if added_length.negative?
          raise 'Detected binding site is longer than the primer sequence.'
        end

        b = { primer: primer,
              site: site,
              offset: offset,
              added_length: added_length }
        bindings.append(b)
        sites.delete(site)
        break
      end
    end
    bindings
  end

  # Finds the first binding site for a Primer on a template.
  #
  # @param template [String] the template sequence
  # @param min_length [FixNum] the minimum length of the binding site
  # @param require_perfect [FixNum] the number of nt from the 3' end that must match perfectly
  # @param allow_mismatch [FixNum] the number of mismatches allowed (doesn't do anything currently)
  # @return [Array<FixNum>] a length 2 array with the start and end position
  def detect_priming_site(template:, min_length: 16, require_perfect: 3, allow_mismatch: 1)
    # TODO: make this work with multiple matches and internal matches
    matches = scan(template, last(require_perfect))
    matches.delete_if { |m| m.offset(0)[1] < min_length }
    return if matches.blank?

    i = 1
    while matches.length > 1
      query = last(require_perfect + i)
      matches.keep_if { |m| expand_match(template, m, i) =~ /#{query}/i }
      i += 1
    end

    _start, stop = matches[0].offset(0)
    return [] unless template[0..stop] =~ /#{last(stop)}/i
    [0, stop]
  end

  # Return the suffix of the sequence of the given length.
  #
  # @param length [FixNum] the number of nucleotides
  # @return [String] the last n nucleotides of the primer sequence
  def last(length)
    sequence[-length..-1]
  end

  # Returns all matches of the pattern in the template sequence.
  #
  # @param template [String] the sequence to be scanned
  # @param pattern [String] the sequence to scan for
  # @return [Array<MatchData>]
  def scan(template, pattern)
    template.to_enum(:scan, /#{pattern}/i).map { Regexp.last_match }
  end

  # Returns the subsequence of the template constructed extended by extending
  # the the matching range by i nucleotides at the front.
  #
  # @param template [String] the template sequence
  # @param match [MatchData] a matching subsequence
  # @param length [FixNum] the length to extend
  def expand_match(template, match, length)
    start, stop = match.offset(0)
    template[(start - length)..stop]
  end
end
