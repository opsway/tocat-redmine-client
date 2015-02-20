module TocatHelper

  class OrderFieldsRows
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

  def current_menu_item
    if /\/tocat/.match(controller.env['PATH_INFO']).present?
      return :tocat if  /\/tocat$/.match(controller.env['PATH_INFO']).present?
      return :orders if  /\/tocat\/orders/.match(controller.env['PATH_INFO']).present?
      return :invoices if  /\/tocat\/invoices/.match(controller.env['PATH_INFO']).present?
    else
      controller.current_menu_item
    end
  end

  def order_fields_rows
    r = OrderFieldsRows.new
    yield r
    r.to_html
  end

  def link_to_new_invoice(order)
    unless order.get_invoice.present?
      return link_to l(:button_add), ''
    end
  end

  def get_paid_icon(invoice)
    if invoice.paid
      return image_tag('true.png')
    else
      return image_tag('false.png')
    end
  end

  def link_to_task(task)
    return link_to "#{task.external_id} - $ #{task.budget}", ''
  end

end
