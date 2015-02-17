class InvoiceReminderMailer < ActionMailer::Base 
  layout false
  include InvoiceReminderHelper
  include InvoicesHelper

  def self.default_url_options
    { :host => Setting.host_name, :protocol => Setting.protocol }
  end

  def invoice_reminders(invoice)
    settings = Setting.plugin_redmine_invoice_reminder
    @invoice = invoice
    @project = @invoice.project
    formatted = format_invoice_reminder
    @from = settings[:invoice_reminder_email_from]
    @subject = formatted[:subject]
    @body = formatted[:body]
    
    headers['X-Invoice-Id'] = @invoice.number

    if settings[:invoice_reminder_email_pdf_attachment].to_i > 0
      attachments[@invoice.filename] = invoice_to_pdf(@invoice)
    end

    Mailer.with_synched_deliveries do
      tos = invoice_email_tos
      tos.each { |to| compose(to).deliver }
      Rails.logger.info "Invoice##{invoice.id} reminder sent to [#{tos.join(', ')}]"
    end
 end

  def compose(to)
    mail(:to => to, :from => @from, :subject => @subject)
  end

  # Warning: code below is too bad to look at.
  # If you are strong, improve it!
  def invoice_to_pdf_wicked_pdf(invoice)
    unless Redmine::Configuration['wkhtmltopdf_exe_path'].blank?
      WickedPdf.config = { :exe_path =>  Redmine::Configuration['wkhtmltopdf_exe_path'] }
    end
    
    view = ActionView::Base.new('plugins/redmine_contacts_invoices/app/views/layouts', {
      :html_preview => false,
      :invoice => invoice
    }, nil, [:pdf])
    view.extend ActionView::Helpers::TagHelper
    view.extend ApplicationHelper
    view.extend Rails.application.routes.url_helpers
    view.instance_eval do
      def l(*a); end
      def link_to(*a); end
      def client_view_invoice_path(*a); end
    end
    
    wicked_pdf = WickedPdf.new
    content = view.render(:text => liquidize_invoice(invoice), :layout => 'invoices.pdf')
    wicked_pdf.pdf_from_string(content,
      :encoding => 'UTF-8',
      :page_size => 'A4',
      :margin => {:top    => 20,                     # default 10 (mm)
                  :bottom => 20,
                  :left   => 20,
                  :right  => 20},
      :footer => {:left => invoice.number, :right => '[page]/[topage]' })
  rescue Exception => e
    e.message
  end
end
