package util;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

@WebListener
public class DonationAgingScheduler implements ServletContextListener {

    private ScheduledExecutorService executor;

    @Override
    public void contextInitialized(ServletContextEvent event) {
        executor = Executors.newSingleThreadScheduledExecutor(new ThreadFactory() {
            @Override
            public Thread newThread(Runnable runnable) {
                Thread thread = new Thread(runnable, "sharehub-donation-aging");
                thread.setDaemon(true);
                return thread;
            }
        });

        executor.scheduleAtFixedRate(new Runnable() {
            @Override
            public void run() {
                DonationAgingService.AgingResult result = new DonationAgingService().expireInactiveDonations();
                System.out.println("ShareHub donation aging: " + result.getMessage()
                        + " Checked=" + result.getChecked()
                        + ", Reminders=" + result.getRemindersSent()
                        + ", Expired=" + result.getExpired());
            }
        }, 2, 24, TimeUnit.HOURS);
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
        if (executor != null) {
            executor.shutdownNow();
        }
    }
}
