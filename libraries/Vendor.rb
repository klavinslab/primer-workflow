# frozen_string_literal: true

# Module to manage details of ordering primers from a vendor using the
# `Cloning/Order Primer` protocol.
#
# Each vendor corresponds to a sub-module of the Vendor module implementing a
# method `order_primer(Primer)`, where `Primer` is defined in the library
# `Sample Models/Primer`
#
module Vendor
  # Returns the vendor selected by the user.
  #
  # @param protocol [Protocol] the protocol where output should be displayed
  # TODO: allow for user to specify which vendors they use with Parameters
  def self.determine_vendor(protocol:)
    vendors = %w[IDT Sigma-Aldrich]
    # vendors = vendors.reject { |v| Parameter.get("#{v} User").blank? }

    vendor_show_hash = protocol.show do
      select(vendors,
             var: 'vendor',
             label: 'Select the vendor you will be ordering primers from',
             default: 0)
    end

    if vendor_show_hash.value?('IDT')
      IDT
    elsif vendor_show_hash.value?('Sigma-Aldrich')
      SigmaAldrich
    end
  end

  # Defines common methods for primer vendors.
  #
  # If you add a vendor, extend the module with this one.
  module PrimerVendor
    # Displays login instructions for the vendor's website.
    #
    # @param protocol [Protocol] the protocol where output should be displayed
    # @param url [String] the URL for the vendor website
    # @param name [String] the login name for the vendor website
    def login_helper(protocol:, url:, name:)
      user = Parameter.get("#{name} User")
      password = Parameter.get("#{name} Password")
      protocol.show do
        title 'Prepare to order primer'

        check "Go to the <a href='#{url}'>#{name} website</a>, log in with " \
              "the account (Username: #{user}, password is #{password})."
        warning 'Ensure that you are logged in to this exact username ' \
                'and password!'
      end
    end

    # Creates a primer table with entries for this vendor.
    # Note: uses vendor module definitions of primer_table_row.
    #
    # @param primers [Array] the primers to be ordered
    def build_primer_table(primers:)
      primers.map do |primer|
        primer_table_row(sample: primer.sample, sequence: primer.sequence)
      end
    end
  end

  # Module for making orders from IDT.
  module IDT
    extend PrimerVendor

    LOWER_LENGTH = 60
    UPPER_LENGTH = 90

    # Displays instructions to login to IDT website.
    #
    # @param protocol [Protocol] the protocol where output should be displayed
    def self.login(protocol:)
      login_helper(
        protocol: protocol,
        url: 'https://www.idtdna.com/site/account',
        name: 'IDT'
      )
    end

    # Returns an array representing a table row.
    #
    # @param sample [Sample] the sample object
    # @param sequence [String] the sequence string for the primer
    def self.primer_table_row(sample:, sequence:)
      [sample.id.to_s + ' ' + sample.name, sequence]
    end

    # Create strings containing identity of primers based on length
    def self.build_primer_lists(primers)
      short_primers = []
      long_primers = []

      primers.each_index do |index|
        primer = primers[index]
        primer_string = "#{primer} (##{index + 1})"
        if primer.length > LOWER_LENGTH && primer.length <= UPPER_LENGTH
          short_primers.push(primer_string)
        elsif primer.length > UPPER_LENGTH
          long_primers.push(primer_string)
        end
      end

      [short_primers.join(', '), long_primers.join(', ')]
    end

    # Shows the primer table that was created in an earlier call and sets the
    # output data.
    #
    # @param protocol [Protocol] the protocol where output should be displayed
    # @param primer_tab [Array<Array<String>>]  matrix for order table
    # @param short_primers [String]  the string of short primers
    # @param long_primers [String]  the string of long primers
    def self.display_primer_table(protocol:, primer_tab:, short_primers:, long_primers:)
      data = protocol.show do
        title 'Create an IDT DNA oligos order'

        if short_primers != ''
          warning "Oligo concentration for primer(s) #{short_primers} will " \
                  'have to be set to "100 nmole DNA oligo."'
        end
        if long_primers != ''
          warning "Oligo concentration for primer(s) #{long_primers} will " \
                  'have to be set to "250 nmole DNA oligo."'
        end

        check 'Under "Custom DNA Oligos", click "DNA Oligos", ' \
              'then click "Order now", and click "Bulk input". ' \
              'Copy and paste the following table there. '
        table primer_tab

        check 'Click Add to Order, review the shopping cart to double check ' \
              'that you entered correctly. ' \
              "There should be #{operations.length} primers in the cart."
        check 'Click Checkout, then click Continue.'
        check 'Enter the payment information, click the oligo card tab, ' \
              'select the Card1 in Choose Payment and then click Submit Order.'
        check 'Go back to the main page, let it sit for 5-10 minutes, ' \
              'return and refresh, and find the order number for the order ' \
              'you just placed.'

        get('text',
            var: 'order_number',
            label: 'Enter the IDT order number below',
            default: 100)
      end

      data[:order_number]
    end

    # Displays the instructions to order the list of primers from IDT.
    #
    # @param primers [Array<Primer>] the list of primers to order
    # @return [String] the order number for the order including the primers
    def self.order_primers(protocol:, primers:)
      primer_table = build_primer_table(primers: primers)
      short_primers, long_primers = build_primer_lists(primers)
      order_number = display_primer_table(protocol: protocol,
                                          primer_tab: primer_table,
                                          short_primers: short_primers,
                                          long_primers: long_primers)

      order_number
    end
  end

  # Module for making primer orders to Sigma-Aldrich.
  module SigmaAldrich
    extend PrimerVendor

    # Displays instructions to login to the Sigma-Adrich website.
    def self.login(protocol:)
      login_helper(
        protocol: protocol,
        url: 'https://www.sigmaaldrich.com/webapp/wcs/stores/servlet/LogonForm?storeId=11001',
        name: 'Sigma-Aldrich'
      )
    end

    # Returns an array representing a table row.
    #
    # @param sample [Sample] the sample object
    # @param sequence [String] the sequence string for the primer
    def self.primer_table_row(sample:, sequence:)
      [
        sample.id.to_s + ' ' + sample.name,
        'None',
        sequence,
        'None',
        '0.025',
        'Desalt',
        'Dry',
        'None',
        '1'
      ].join('\t')
    end

    # Displays the primer table for vendor Sigma-Aldrich.
    #
    # @param primer_table [Array<Array<String>>] the table of primer details
    def self.show_primer_table(protocol:, primer_table:)
      protocol.show do
        title 'Create a Sigma-Aldrich DNA oligos order'

        check 'Under "Products", click "Custom DNA Oligos", and then under ' \
              '"Standard DNA Oligos", click "Order" under "Tubes".'
        check 'Click "Upload or Copy & Paste".'
        check 'Copy and paste the following table and click submit.'

        table primer_table

        check 'Click Add to Cart.'
        check 'Proceed to Check Out.'
        check 'Click Check Out and confirm the order.'
      end
    end

    # Displays the instructions to order the list of primers from Sigma-Aldrich.
    #
    # @param primers [Array<Primer>] the list of primers to order
    # @return [nil] since no order number is given
    def self.order_primers(protocol:, primers:)
      primer_table = build_primer_table(primers: primers)
      show_primer_table(protocol: protocol, primer_table: primer_table)

      nil
    end
  end
end
