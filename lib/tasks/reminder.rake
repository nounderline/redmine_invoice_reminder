desc <<-END_DESC
Send reminders about overdue invoices.
END_DESC

namespace :redmine_invoice_reminder do
  # TODO: use raw SQL for better performance with support
  #       for multiple SQL dialects (sqlite, mysql, postgresql)
  task :send_reminders => :environment do
    now = Date.today
    invoices = Invoice.includes(:contact, :project)
                      .where(:status_id => Invoice::SENT_INVOICE)

    Rails.logger = Logger.new(STDOUT)

    invoices.each do |invoice|
      due = invoice.due_date.to_date
 
      # Remind only when due is today, 3 day before due,
      # or every even day after due.
      if (due === Date.today) or (due === 3.days.from_now.to_date) \
        or (due < now && (due - now).to_i.even?)
        InvoiceReminderMailer.invoice_reminders(invoice)
      end
    end
  end
end


