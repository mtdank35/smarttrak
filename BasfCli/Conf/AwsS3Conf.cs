using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BasfCli.Conf
{
    public class AwsS3Conf
    {
        public string ServiceURL { get; set; }
        public string AccessKey { get; set; }
        public string SecretKey { get; set; }
        public string BucketName { get; set; }

        public AwsS3Conf()
        {
            ServiceURL = "objects.basf.com";
            AccessKey = "{AccessKey}";
            SecretKey = "{SecretKey}";
            BucketName = "{BucketName}";
        }
    }
}
