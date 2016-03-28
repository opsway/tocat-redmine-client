module TocatHelper
  def get_paid_icon(invoice)
    if invoice.paid
      return image_tag('true.png')
    else
      return image_tag('false.png')
    end
  end

  def zoho_chart_prev_quarter_url(user)
    "https://reports.zoho.com/ZDBChartEmbed.png?OBJID=1030771000000164280&STANDALONE=true&privatelink=5f61cf590aa11f8782e49fbd3d3512b2&WIDTH=550&HEIGHT=340&LP=NONE&INTERVAL=-1&TITLE=true&DESCRIPTION=false&ZOHO_CRITERIA=%22User%20login%22=%27#{user.login}%27"
  end

  def zoho_chart_this_quarter_url(user)
    "https://reports.zoho.com/ZDBChartEmbed.png?OBJID=1030771000000164264&STANDALONE=true&privatelink=becea1c0eb82695f1c025debea7b564f&WIDTH=550&HEIGHT=340&LP=NONE&INTERVAL=-1&TITLE=true&DESCRIPTION=false&ZOHO_CRITERIA=%22User%20login%22=%27#{user.login}%27"
  end
end
