class InvoiceReminderMailer < ActionMailer::Base
  include Redmine::I18n
  include InvoiceReminderHelper
  include InvoicesHelper
  helper :invoices

  def has_email(formatted)
    formatted == @to or @bcc.include?(formatted)
  end

  def invoice_reminder(invoice)
    @invoice = invoice
    @contact = @invoice.contact
    settings = Setting[:plugin_redmine_invoice_reminder]
    recipients = settings[:invoice_reminder_email_recipients]
    user_ids, role_ids = [], []
    @to = ''
    @bcc = []
    body = format_invoice_reminder_body(@invoice, settings[:invoice_reminder_email_body])

    # look for recipients from settings
    recipients.each do |name|
      if name.start_with? 'u_'
        id = name.split('u_')[1]
        user_ids << id
      end

      if name.start_with? 'r_'
        id = name.split('r_')[1]
        role_ids << id
      end

      if name == '_contact'
        to = "#{@contact.name} <#{@contact.email}>"
      end
    end

    # prepare recipients' adressess for mail formating
    if user_ids.present?
      User.find(user_ids).each do |user|
        formatted = "#{user.name} <#{user.mail}>"
        @bcc << formatted if !self.has_email(formatted)
      end
    end
    if role_ids.present?
      Role.find(role_ids).each do |role|
        @bcc += role.members.map { |r|
          formatted = "#{r.user.name} <#{r.user.mail}>"
          next if self.has_email(formatted)
          formatted
        }
      end
    end

    p @bcc

    if settings[:invoice_reminder_email_pdf_attachment].to_i > 0
      attachments[@invoice.filename] = invoice_to_pdf(@invoice)
    end

    mail :from => 'admin1@eoiui.com',
         :to => @to,
         :bcc => @bcc,
         :subject => settings[:invoice_reminder_email_subject],
         :body => body
  end
end