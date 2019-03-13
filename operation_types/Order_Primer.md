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
def precondition(op)
  return true
  
  pending_orders = Operation.where("status = ? && operation_type_id IN (?)", "pending", OperationType.where("name = 'Order Primer'").map { |order| order.id })
  total_cost = pending_orders.inject(0) { |sum, order| sum + order.nominal_cost[:materials] }
  
  if (op.input("Urgent?").val.downcase == "yes" ||
     pending_orders.any? { |order| order.input("Urgent?").val.downcase == "yes" } ||
     total_cost > 50 ) && op.output("Primer").sample.properties["Overhang Sequence"] && op.output("Primer").sample.properties["Anneal Sequence"]
      return true
  end
  
  return false
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# frozen_string_literal: true

needs 'Standard Libs/Feedback'
needs 'Cloning/PrimerModel'
needs 'Cloning/Vendor'

class Protocol
  include Feedback
  include PrimerModel

  def main
    operations.retrieve.make

    vendor = Vendor.determine_vendor
    vendor.login

    primers = operations.map { |op| create_primer(output: op.output('Primer')) }
    order_number = vendor.order_primers(primers)
    add_order_number(operations: operations, order_number: order_number)

    get_protocol_feedback
    {}
  end

  def create_primer(output:)
    Primer.new(sample: output.sample)
  end

  def add_order_number(operations:, order_number:)
    unless order_number.nil?
      operations.each do |op|
        op.set_output_data('Primer', :order_number, order_number)
      end
    end
  end
end

```
