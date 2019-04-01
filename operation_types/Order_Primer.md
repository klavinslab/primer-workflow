# Order Primer

# OrderPrimer

Displays instructions to order DNA oligos for the specified output primer from a vendor.

Indicate whether the order is urgent using the `Urgent?` parameter.

Currently supported vendors are IDT and Sigma-Aldrich.
Use the **Parameters** menu to set the user and password for the vendor(s) you want to be able to use.
Set values for `IDT User` and `IDT Password` for IDT; and `Sigma-Aldrich User` and `Sigma-Aldrich Password` for Sigma-Aldrich.

See the `Cloning/Vendor` library to add a vendor.



### Parameters

- **Urgent?** 

### Outputs


- **Primer** [P]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer")'>Primer</a> / <a href='#' onclick='easy_select("Containers", "Lyophilized Primer")'>Lyophilized Primer</a>

### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
# frozen_string_literal: true

# Test the precondition for the given Order Primer operation.
#
# The output primer may not be ordered if the Sample does not have an overhang
# or annealing sequence.  Otherwise, it may be ordered if one of the following
# holds:
# - the primer order is urgent,
# - the total cost of all pending orders exceeds $50, or
# - there are other orders that are urgent.
#
# @param operation [Operation] the Order Primer operation
# @return [Boolean] true if the primer can be ordered, or false otherwise
def precondition(operation)
  # TODO: let user know that primers don't have necessary structure
  primer_sample = operation.output('Primer').sample
  return false unless primer_sample.properties['Overhang Sequence'].present?
  return false unless primer_sample.properties['Anneal Sequence'].present?

  return true if urgent?(operation)

  pending_orders = Operation.where('status IN (?) && operation_type_id IN (?)',
                                   %w[waiting pending delayed],
                                   operation.operation_type.id)
  total_cost = pending_orders.inject(0) do |sum, order|
    sum + order.nominal_cost[:materials]
  end
  return true if total_cost > 50

  pending_orders.any? { |order_operation| urgent?(order_operation) }
end

# Indicate whether the operation has the urgent input parameter set.
#
# @param operation [Operation] the Order Primer operation
# @return [Boolean] true if the urgent parameter is set, false otherwise
def urgent?(operation)
  urgent_parameter = operation.input('Urgent?').val

  urgent_parameter.present? && urgent_parameter.casecmp?('yes')
end

```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# frozen_string_literal: true

needs 'Standard Libs/Feedback'
needs 'Sample Models/Primer'
needs 'Cloning/Vendor'

# Order Primer protocol.
#
# Protocol to order primers from a vendor selected by the user from vendors
# supported by the Vendor module.
# Uses the vendor module to provide instructions to order the primers, and
# then adds the order number as an association for each of the primer outputs.
class Protocol
  include Feedback
  include Vendor

  def main
    operations.retrieve.make

    vendor = Vendor.determine_vendor(protocol: self)
    vendor.login(protocol: self)

    primers = operations.map { |op| create_primer(output: op.output('Primer')) }
    order_number = vendor.order_primers(protocol: self, primers: primers)
    add_order_number(operations: operations, order_number: order_number)

    get_protocol_feedback
    {}
  end

  # Create a Primer object from the Item of the given output.
  #
  # @param output [FieldValue] the output value
  # @return [Primer] the primer object for the Sample of the output Item
  def create_primer(output:)
    Primer.new(sample: output.item.sample)
  end

  # Add the given order number to all operations in the operations list
  # unless the order number is nil or the empty string.
  #
  # @param operations [OperationsList] the list of operations
  # @param order_number [String] the order number for 
  def add_order_number(operations:, order_number:)
    return if order_number.blank?
    operations.each do |op|
      op.set_output_data('Primer', :order_number, order_number)
    end
  end
end

```
