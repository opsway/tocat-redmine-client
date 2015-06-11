module OrdersHelper
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

  def order_fields_rows
    r = OrderFieldsRows.new
    yield r
    r.to_html
  end

  def delete_link(order)
    if User.current.tocat_allowed_to?(:destroy_orders) && !order.sub_orders.any? && !order.completed && !order.parent.try(:completed)
      return link_to l(:button_delete), '', :data => {:confirm => l(:confirm_order_destroy)}, :method => :delete, :class => 'icon icon-del'
    end
  end

  def link_to_task(task)
    return link_to "#{task.external_id}", issue_path(task.external_id)
  end

  def link_to_new_invoice(order)
    unless order.get_invoice.present?
      return link_to l(:button_add), new_invoice_path(params: {order: order.id})
    end
  end

  def get_paid_icon(invoice)
    if invoice.paid
      return image_tag('true.png')
    else
      return image_tag('false.png')
    end
  end

  def sort_link(column, caption, default_order)
    css, order = nil, default_order

    if column.to_s == @sort_criteria.first_key
      if @sort_criteria.first_asc?
        css = 'sort asc'
        order = 'desc'
      else
        css = 'sort desc'
        order = 'asc'
      end
    end
    caption = column.to_s.humanize unless caption

    sort_options = { :sort => "#{column}:#{order}".to_param }
    url_options = params.merge(sort_options)

    url_options = url_options.merge(:project_id => params[:project_id]) if params.has_key?(:project_id)

    link_to_content_update(h(caption), url_options, :class => css)
  end
end
