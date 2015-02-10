class InvoiceReminderMailer < ActionMailer::Base
  include AbstractController::Callbacks # @SUPPORT Rails 3
  include Redmine::I18n
  include InvoiceReminderHelper
  include InvoicesHelper
  helper :invoices

  # TODO: use raw SQL for better performance with support
  #       for multiple SQL dialects (sqlite, mysql, postgresql)
  def send_invoice_reminders()
    now = Date.today
    settings = Setting.plugin_redmine_invoice_reminder
    invoices = Invoice.where(:status_id => Invoice::SENT_INVOICE).where("due_date IS NOT NULL")

    invoices.each do |invoice|
      due = invoice.due_date.to_date

      find_invoice_recipients invoice

      # Remind only when due is today, 3 day before due,
      # or every even day after due
      if due.today? or (due === 3.days.ago.to_date) \
        or (due > now && (due - now).to_i.even?)

        @recipients.each do |recipient|
         invoice_reminder(invoice, recipient).deliver
        end

        Rails.logger.info("Invoice##{invoice.id} reminder sent to [#{@recipients.join(', ')}]")
      end
    end
  end

  def invoice_reminder(invoice, recipient)
    settings = Setting.plugin_redmine_invoice_reminder
    body = format_invoice_reminder_body(invoice, settings[:invoice_reminder_email_body])

    if settings[:invoice_reminder_email_pdf_attachment].to_i > 0
      attachments[invoice.filename] = invoice_to_pdf(invoice)
    end

    mail :from => settings[:invoice_reminder_email_from],
         :to => recipient,
         :subject => settings[:invoice_reminder_email_subject],
         :body => body
  end

  private

    def add_recipient(formatted)
      @recipients << formatted if not has_recipient?(formatted)
    end

    def has_recipient?(formatted)
      @recipients.include?(formatted)
    end

    # Search for recipients provided in plugin settings
    def find_invoice_recipients(invoice)
      @invoice = invoice
      @recipients = []
      settings = Setting.plugin_redmine_invoice_reminder
      codes = settings[:invoice_reminder_email_recipients]
      user_ids, role_ids = [], []

      # look for recipients from settings
      codes.each do |code|
        if code.start_with? 'u_'
          id = code.split('u_')[1]
          user_ids << id
          next
        end

        if code.start_with? 'r_'
          id = code.split('r_')[1]
          role_ids << id
          next
        end

        if code == '_contact'
          contact = invoice.contact
          @recipients << "#{contact.name} <#{contact.email}>" if contact
        end
      end

      # prepare recipients' adressess for mail formating
      if user_ids.present?
        User.find(user_ids).each do |user|
          add_recipient "#{user.name} <#{user.mail}>" if user.member_of? @invoice.project
        end
      end
      if role_ids.present?
        Role.find(role_ids).each do |role|
          role.members.each do |role|
            user = role.user;
            if user and user.member_of? @invoice.project
              add_recipient "#{user.name} <#{user.mail}>"
            end
          end
        end
      end
      
    end
end