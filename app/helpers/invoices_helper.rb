module InvoicesHelper

  class InvoiceFieldsRows
    include ActionView::Helpers::TagHelper

    def initialize
      @left = []
      @right = []
    end

    def left(*args)
      args.any? ? @left << cells(*args) : @left
    end

    def right(*args)
      args.any? ? @right << cells(*args) : @right
    end

    def size
      @left.size > @right.size ? @left.size : @right.size
    end

    def to_html
      html = ''.html_safe
      blank = content_tag('th', '') + content_tag('td', '')
      size.times do |i|
        left = @left[i] || blank
        right = @right[i] || blank
        html << content_tag('tr', left + right)
      end
      html
    end

    def cells(label, text, options={})
      content_tag('th', "#{label}:", options) + content_tag('td', text, options)
    end
  end

  def invoice_fields_rows
    r = InvoiceFieldsRows.new
    yield r
    r.to_html
  end

  def get_paid_icon(invoice)
    if invoice.paid
      return image_tag('true.png')
    else
      return image_tag('false.png')
    end
  end

  def link_to_order(order)
    link_to "#{order.name} - $#{order.invoiced_budget}:#{order.free_budget}", order_path(order.id)
  end
end
