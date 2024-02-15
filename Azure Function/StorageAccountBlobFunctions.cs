using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace oshrcosdcloud_stor
{
    public class StorageAccountBlobFunctions
    {
        private const string ContainerName = "items";
        private const string BlobConnection = "blobConnection";

        private ILogger<StorageAccountBlobFunctions> _logger;

        public StorageAccountBlobFunctions(ILogger<StorageAccountBlobFunctions> logger)
        {
            _logger = logger;
        }

        [FunctionName("BlobTrigger")]
        public async Task BlobTriggerAsync([BlobTrigger($"{ContainerName}/{{name}}", Connection = BlobConnection)] Stream myBlob, string name)
        {
            using var reader = new StreamReader(myBlob);
            var body = await reader.ReadToEndAsync();
            _logger.LogInformation($"C# Blob trigger function Processed blob\n Name:{name} \n with content: {body}");
        }

        [FunctionName("BlobOutput")]
        public async Task BlobOutputAsync([HttpTrigger(AuthorizationLevel.Anonymous, "POST", Route = "insert")] HttpRequest req,
            [Blob($"{ContainerName}/test", FileAccess.Write, Connection = BlobConnection)] Stream myBlob)
        {
            using var reader = new StreamReader(req.Body);
            var body = await reader.ReadToEndAsync();

            using var writer = new StreamWriter(myBlob);
            await writer.WriteAsync(body);
        }

        [FunctionName("BlobInput")]
        public async Task<IActionResult> BlobInputAsync([HttpTrigger(AuthorizationLevel.Anonymous, "POST", Route = "read")] HttpRequest req,
            [Blob($"{ContainerName}/test", FileAccess.Read, Connection = BlobConnection)]Stream myBlob
            )
        {
            if(myBlob == null)
            {
                return new NotFoundResult();
            }
            using var reader = new StreamReader(myBlob);
            var body = await reader.ReadToEndAsync();
            return new OkObjectResult(body);
        }
    }
}
