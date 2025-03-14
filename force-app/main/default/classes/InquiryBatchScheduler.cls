global class InquiryBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        InquiryBatchApex batch = new InquiryBatchApex();
        Database.executeBatch(batch);
    }
}