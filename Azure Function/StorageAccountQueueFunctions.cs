using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System.Runtime.Serialization;
using System.IO;
using Microsoft.AspNetCore.Http;
using System.Threading.Tasks;

namespace oshrcosdcloud_stor
{
    public class StorageAccountQueueFunctions
    {
        private const string BlobConnection = "blobConnection";
        private const string QueueName = "queue";
        private ILogger<StorageAccountQueueFunctions> _logger;

        public StorageAccountQueueFunctions(ILogger<StorageAccountQueueFunctions> logger)
        {
            _logger = logger;
        }

        [FunctionName("QueueTrigger")]
        public void QueueTrigger([QueueTrigger(QueueName, Connection = BlobConnection)] string myQueueItem)
        {
            _logger.LogInformation($"Queue messaged: {myQueueItem}");
        }

        [FunctionName("QueueOutput")]
        [return: Queue(QueueName, Connection = BlobConnection)]
        public async Task<string> QueueOutputAsync([HttpTrigger(AuthorizationLevel.Anonymous, "POST", Route = "queue-add")] HttpRequest req)
        {
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            _logger.LogInformation($"Queue messaged added: {body}");
            return body;
        }

        
    }

    [DataContract]
    public record QueueMessage
    {
        [DataMember]
        public string Message { get; set; }
    }
}
