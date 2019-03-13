# Make Primer Aliquot

name: Make Primer Aliquot
---

category: Cloning
---

This protocol uses an existing Primer stock in inventory to make a 1:10 diluted 100L aliquot of that primer.


## Arguments

- `Stock` &mdash; input primer stock

## Parameters

_None_

## Output

- `Aliquot` &mdash; the output 1:10 diluted primer aliquot.

## Shared (Blackboard) attributes

_None_

## Data associations

_None_

### Item associations

_None_

### Operation associations

_None_

### Plan associations

_None_

## Equipment

_None_

## Supplies

_None_











### Inputs


- **Stock** [P]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer")'>Primer</a> / <a href='#' onclick='easy_select("Containers", "Primer Stock")'>Primer Stock</a>



### Outputs


- **Aliquot** [P]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer")'>Primer</a> / <a href='#' onclick='easy_select("Containers", "Primer Aliquot")'>Primer Aliquot</a>

### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
def precondition(op)
  true
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# frozen_string_literal: true

# Make Primer Aliquot protocol.
#
# For each input primer stock, transfers 10 uL of stock into 90 uL of water in
# a 1.5 mL tube.
class Protocol
  def main
    operations.retrieve.make

    gather_tubes(
      count: operations.length,
      aliquot_ids: operations.map { |op| op.output('Aliquot').item.id }
    )
    create_aliquots(operations)

    operations.store
  end

  # Gather and prepare tubes for new aliquots.
  #
  # @param count [FixNum] the number of tubes to prepare
  # @param aliquot_ids [Array<FixNum>] the item IDs to label tubes
  def gather_tubes(count:, aliquot_ids:)
    show do
      title 'Prepare aliquot tubes'

      note "Grab #{count} 1.5 mL tubes"
      note "Label each tube with the following ids: #{aliquot_ids.to_sentence}"
      note 'Using the 100 uL pipette, pipette 90uL of water into each tube'
    end
  end

  # Displays instructions to transfer 10 uL of primer stock into the tube with
  # the corresponding label.
  #
  # @param operations [OperationList] the operations specifying transfer
  def create_aliquots(operations)
    show do
      title 'Transfer primer stock into primer aliquot'

      note 'Pipette 10 uL of the primer stock into a tube according to the following table:'
      table operations
        .start_table
        .input_item('Stock')
        .output_item('Aliquot', checkable: true)
        .end_table
    end
  end
end

```
