# frozen_string_literal: true

module Units
  # Volume
  MICROLITERS = 'l'
  MILLILITERS = 'mL'

  # Weight
  NANOGRAMS = 'ng'

  # Concentration
  PICOMOLAR = 'pM'
  NANOMOLAR = 'nM'
  MICROMOLAR = 'M'
  MILLIMOLAR = 'mM'
  MOLAR = 'M'

  # Temperature
  DEGREES_C = 'C'

  # Time
  MINUTES = 'min'
  SECONDS = 'sec'
  HOURS = 'hr'

  # Force
  TIMES_G = 'x g'

  def qty_display(qty)
    "#{qty[:qty]} #{qty[:units]}"
  end

  def add_qty_display(options)
    new_items = {}

    options.each do |key, value|
      key =~ /^(.+_)+([a-z]+)$/

      case Regexp.last_match(2)
      when 'microliters'
        units = MICROLITERS
      when 'milliliters'
        units = MILLILITERS
      when 'minutes'
        units = MINUTES
      else
        next
      end

      qty = value.to_f

      new_items["#{Regexp.last_match(1)}qty".to_sym] = { qty: qty, units: units }
    end

    options.update(new_items)
  end
end
