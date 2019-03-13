# Rehydrate Primer

# Rehydrate Primer

Takes a primer and hydrates it, yielding a primer aliquot and a primer stock.

This protocol assumes that all primers in the job are from the same order.
In practice, the BIOFAB ensures this by telling IDT to only send an order once
all primers are complete.
This allows the lab managers to identify and schedule the appropriate job.

### Inputs


- **Primer** [P]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer")'>Primer</a> / <a href='#' onclick='easy_select("Containers", "Lyophilized Primer")'>Lyophilized Primer</a>



### Outputs


- **Primer Aliquot** [P]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer")'>Primer</a> / <a href='#' onclick='easy_select("Containers", "Primer Aliquot")'>Primer Aliquot</a>

- **Primer Stock** [P]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer")'>Primer</a> / <a href='#' onclick='easy_select("Containers", "Primer Stock")'>Primer Stock</a>

### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
def precondition(op)
  true
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# frozen_string_literal: true

needs 'Standard Libs/Feedback'
needs 'Cloning/PrimerModel'

# Rehydrate Primers protocol.
# Takes a primer and hydrates it yielding a primer aliquot and stock.
#
# Note: this protocol assumes details about vendor labeling that may be
# IDT-specific.
#
class Protocol
  include Feedback
  include PrimerModel

  def main
    operations.retrieve interactive: false
    operations.make

    spin_down_primers(operations)
    get_primer_nm(operations)

    rehydrate_primers(operations)
    aliquot_ids = operations.map do |op|
      op.output('Primer Aliquot').item.id
    end
    prepare_aliquot_tubes(tube_ids: aliquot_ids)
    vortex_and_centrifuge(count: operations.length)
    make_aliquots(operations)

    operations.each { |op| op.input('Primer').item.mark_as_deleted }
    operations.store

    get_protocol_feedback
    {}
  end

  # Display instructions to spin down the primers
  #
  # @param primers [Array<Item>] the input primers
  def spin_down_primers(_primers)
    show do
      title 'Quick spin down all the primer tubes'
      note 'Put all the primer tubes in a table top centrifuge to spin down for 3 seconds.'
      warning 'Make sure to balance!'
    end
  end

  # Displays the primers and for each asks for the nMoles of primer on the tube
  # label. Stores the measurement in `operation.temporary[:n_moles]`
  def get_primer_nm(operations)
    show do
      title 'Enter the nMoles of the primer'

      note 'Enter the number of moles for each primer, in nM. This is written toward the bottom of the tube, below the MW.'
      note "The ID of the primer is listed before the primer's name on the side of the tube."
      table operations
        .start_table
        .input_sample('Primer')
        .get(:n_moles, type: 'number', heading: 'nMoles', default: 10)
        .end_table
    end
  end

  # Displays instructions to label the primer tubes with a new ID, and then add
  # TE to rehydrate the primer.  Adds 10uL for each nM.
  #
  # @param operations [OperationList] the operations with input primers
  def rehydrate_primers(operations)
    show do
      title 'Label and rehydrate'

      note 'Label each primer tube with the IDs shown in Primer Stock IDs and rehydrate with volume of TE shown in Rehydrate'
      table operations
        .start_table
        .input_sample('Primer')
        .output_item('Primer Stock')
        .custom_column(heading: 'Rehydrate (uL of TE)', checkable: true) { |op| op.temporary[:n_moles] * 10 }
        .end_table
    end
  end

  # Displays instructions to vortex and centrifuge the rehydrated primers.
  #
  # @param count [Fixnum] the number of primers
  def vortex_and_centrifuge(count:)
    show do
      title 'Vortex and centrifuge'
      note 'Wait one minute for the primer to dissolve in TE.' if count < 7
      note 'Vortex each tube on table-top vortexer for 5 seconds and then quick spin for 2 seconds on table top centrifuge.'
    end
  end

  # Displays instructions to prepare the aliquot tubes by labeling and adding
  # 90uL of water to each.
  #
  # @param tube_ids [Array<Fixnum>] the list of item IDs
  def prepare_aliquot_tubes(tube_ids:)
    count = tube_ids.length
    id_string = tube_ids.map(&:to_s).join(', ')
    show do
      title 'Prepare 1.5 mL tubes'

      note 'While the primer dissolves in the TE, prepare tubes for each aliquot'
      check "Grab #{count} 1.5 mL tubes, label with following ids: #{id_string}"
      check 'Add 90 uL of water into each above tube.'
    end
  end

  # Displays instructions to transfer 10uL of the primer stock. into each output tube.
  #
  # @param operations [OperationList] the operations with output primers
  def make_aliquots(operations)
    show do
      title 'Make primer aliquots'

      note 'Add 10 uL from each primer stock into each primer aliquot tube using the following table.'

      table operations
        .start_table
        .output_item('Primer Stock', heading: 'Primer Stock (10 uL)')
        .output_item('Primer Aliquot', checkable: true)
        .end_table
      note 'Vortex each tube after the primer has been added.'
    end
  end
end

```
