using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Azure;
using Microsoft.AspNetCore.Http;
using System.IO;
using Newtonsoft.Json;

namespace oshrcosdcloud_stor
{
    internal class StorageAccountTableStorageFunctions
    {
        private const string BlobConnection = "blobConnection";
        private const string TableName = "table";
        private ILogger<StorageAccountTableStorageFunctions> _logger;

        public StorageAccountTableStorageFunctions(ILogger<StorageAccountTableStorageFunctions> logger)
        {
            _logger = logger;
        }

        [FunctionName("TableInput")]
        public async Task<IActionResult> BlobTriggerAsync([HttpTrigger(AuthorizationLevel.Anonymous, "GET", Route = "table-get/{partition}/{id}")] HttpRequest req,
            [Table(TableName, "{partition}", "{id}")] TableEntity item)
        {
            await Task.Delay(0); // Add an await statement here to make the method asynchronous.
            return new OkObjectResult(item);
        }

        [FunctionName("TableOutput")]
        [return: Table(TableName, Connection = BlobConnection)]
        public async Task<TableEntity> BlobOutputAsync([HttpTrigger(AuthorizationLevel.Anonymous, "POST", Route = "table-add")] HttpRequest req)
        {
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();
            _logger.LogInformation($"Queue messaged added: {body}");
            return JsonConvert.DeserializeObject<TableEntity>(body);
        }

        public class TableEntity : Azure.Data.Tables.ITableEntity
        {
            public string Name { get; set; }
            public string PartitionKey { get; set; }
            public string RowKey { get; set; }
            public DateTimeOffset? Timestamp { get; set; }
            public ETag ETag { get; set; }
        }
    }
}
