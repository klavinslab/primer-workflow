# frozen_string_literal: true

# Module to manage details of ordering primers from a vendor using the `Cloning/Order Primer` protocol.
#
# Each vendor corresponds to a sub-module of the Vendor module implementing a
# method `order_primer(Primer)`, where `Primer` is defined in the library `Cloning/PrimerModel`
#
module Vendor
  # This is a hack to allow the methods of this module to create show blocks
  class Wrapper
    include Krill::Base
  end

  # Returns the vendor specified by the user
  # TODO: allow for user to specify which vendors they use with Parameters
  def self.determine_vendor
    vendors = %w[IDT Sigma-Aldrich]
    #vendors = vendors.reject { |v| Parameter.get("#{v} User").blank? }

    vendor_show_hash = Wrapper.new.show do
      select vendors, var: 'vendor', label: 'Select the vendor you will be ordering primers from', default: 0
    end

    if vendor_show_hash.value?('IDT')
      IDT
    elsif vendor_show_hash.value?('Sigma-Aldrich')
      SigmaAldrich
    end
  end

  # Defines common methods for primer vendors.
  #
  # Each vendor should have a module that includes this one.
  module PrimerVendor
    # will need to store information for each vendor

    # Displays login instructions for the vendor's website.
    def login_helper(url:, name:)
      user = Parameter.get("#{name} User")
      password = Parameter.get("#{name} Password")
      Wrapper.new.show do
        title 'Prepare to order primer'

        check "Go to the <a href='#{url}'>#{name} website</a>, log in with the account (Username: #{user}, password is #{password})."
        warning 'Ensure that you are logged in to this exact username and password!'
      end
    end

    # creates a primer table for copy-pasting
    def build_primer_table(primers:)
      primers.map do |primer|
        primer_table_entry(sample: primer.sample, sequence: primer.sequence)
      end
    end
  end

  # stores IDT information
  module IDT
    extend PrimerVendor

    LOWER_LENGTH = 60
    UPPER_LENGTH = 90

    def self.login
      login_helper(
        url: 'https://www.idtdna.com/site/account',
        name: 'IDT'
      )
    end

    def self.primer_table_entry(sample:, sequence:)
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

    # shows the primer table that was created in an earlier call and sets the output data.
    def self.display_primer_table(primer_tab, short_primers, long_primers)
      data = Wrapper.new.show do
        title 'Create an IDT DNA oligos order'

        warning "Oligo concentration for primer(s) #{short_primers} will have to be set to \"100 nmole DNA oligo.\"" if short_primers != ''
        warning "Oligo concentration for primer(s) #{long_primers} will have to be set to \"250 nmole DNA oligo.\"" if long_primers != ''

        check 'Under "Custom DNA Oligos", click "DNA Oligos", then click "Order now", and click "Bulk input". Copy and paste the following table there. '
        table primer_tab

        check "Click Add to Order, review the shopping cart to double check that you entered correctly. There should be #{operations.length} primers in the cart."
        check 'Click Checkout, then click Continue.'
        check 'Enter the payment information, click the oligo card tab, select the Card1 in Choose Payment and then click Submit Order.'
        check 'Go back to the main page, let it sit for 5-10 minutes, return and refresh, and find the order number for the order you just placed.'

        get 'text', var: 'order_number', label: 'Enter the IDT order number below', default: 100
      end

      data[:order_number]
    end

    def self.order_primers(primers)
      primer_table = build_primer_table(primers: primers)
      short_primers, long_primers = build_primer_lists(primers)
      order_number = display_primer_table(primer_table, short_primers, long_primers)

      order_number
    end
  end

  # stores Sigma-Aldrich information
  module SigmaAldrich
    extend PrimerVendor

    def self.login
      login_helper(
        url: 'https://www.sigmaaldrich.com/webapp/wcs/stores/servlet/LogonForm?storeId=11001',
        name: 'Sigma-Aldrich'
      )
    end

    def self.primer_table_entry(sample:, sequence:)
      [sample.id.to_s + ' ' + sample.name + "\t" + "None\t" + sequence + "\tNone\t" + "0.025\t" + "Desalt\t" + "Dry\t" + "None\t" + '1']
    end

    # shows the primer table for if the vendor is Sigma-Aldrich
    def self.show_primer_table(primer_table)
      Wrapper.new.show do
        title 'Create a Sigma-Aldrich DNA oligos order'

        check 'Under "Products", click "Custom DNA Oligos", and then under "Standard DNA Oligos", click "Order" under "Tubes".'
        check 'Click "Upload or Copy & Paste".'
        check 'Copy and paste the following table and click submit.'

        table primer_table

        check 'Click Add to Cart.'
        check 'Proceed to Check Out.'
        check 'Click Check Out and confirm the order.'
      end
      # TODO: how is order number handled here?
    end

    def self.order_primers(primers)
      primer_table = build_primer_table(primers: primers)
      order_number = show_primer_table(primer_table)

      order_number
    end
  end
end
