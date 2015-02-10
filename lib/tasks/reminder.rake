desc <<-END_DESC
Send reminders about overdue invoices.
END_DESC

namespace :redmine_invoice_reminder do
  task :send_reminders => :environment do
    # Save all logs to STDOUT for cron output
    Rails.logger = Logger.new(STDOUT)

    InvoiceReminderMailer.send_invoice_reminders
  end
end
