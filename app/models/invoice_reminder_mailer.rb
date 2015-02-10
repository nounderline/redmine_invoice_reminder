class InvoiceReminderMailer < ActionMailer::Base
  include Redmine::I18n
  include InvoiceReminderHelper
  include InvoicesHelper
  helper :invoices

  def has_email(formatted)
    formatted == @_to or @_bcc.include?(formatted)
  end

  def invoice_reminder(invoice)
    @_invoice = invoice
    @_contact = @_invoice.contact
    settings = Setting[:plugin_redmine_invoice_reminder]
    recipients = settings[:invoice_reminder_email_recipients]
    user_ids, role_ids = [], []
    @_to = ''
    @_bcc = []
    body = format_invoice_reminder_body(@_invoice, settings[:invoice_reminder_email_body])

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
        @_to = "#{@_contact.name} <#{@_contact.email}>"
      end
    end

    # prepare recipients' adressess for mail formating
    if user_ids.present?
      User.find(user_ids).each do |user|
        formatted = "#{user.name} <#{user.mail}>"
        @_bcc << formatted if !self.has_email(formatted)
      end
    end
    if role_ids.present?
      Role.find(role_ids).each do |role|
        @_bcc += role.members.map { |r|
          formatted = "#{r.user.name} <#{r.user.mail}>"
          next if self.has_email(formatted)
          formatted
        }
      end
    end

    if settings[:invoice_reminder_email_pdf_attachment].to_i > 0
      attachments[@_invoice.filename] = invoice_to_pdf(@_invoice)
    end

    mail :from => settings[:invoice_reminder_email_from],
         :to => @_to,
         :bcc => 'br@dsa.pl',
         :subject => settings[:invoice_reminder_email_subject],
         :body => body
  end
end