using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace BasfSvr.ServiceModel.Exceptions
{
    public class DoesNotExistsException : Exception
    {
        public DoesNotExistsException()
        { }

        protected DoesNotExistsException(SerializationInfo info, StreamingContext context) : base(info, context)
        { }

        public DoesNotExistsException(string message, Exception innerException) : base(message, innerException)
        { }

        public DoesNotExistsException(string message) : base(message)
        { }
    }
}
