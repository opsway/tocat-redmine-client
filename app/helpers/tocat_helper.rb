module TocatHelper
  def get_paid_icon(invoice)
    if invoice.paid
      return image_tag('true.png')
    else
      return image_tag('false.png')
    end
  end
end
