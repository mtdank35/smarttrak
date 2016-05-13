using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net.NetworkInformation;
using System.Runtime.InteropServices;

namespace BasfCli.Commands.Misc
{
	[CommandHelp("Display system information")]
	public class SysinfoCommand : ApplicationCommand
	{
		private readonly TextWriter _writer;

		public SysinfoCommand(TextWriter writer)
		{
			_writer = writer;
		}

		protected override void InnerExecute(string[] arguments)
		{
            var info = new SysInfo();
            _writer.WriteLine("");
            _writer.WriteLine("-- System Info --");
            _writer.WriteLine("");
            _writer.WriteLine(info.GetJson());
        }

        private class SysInfo
        {
            public string MachineName { get; set; }
            public string UserName { get; set; }
            public string Domain { get; set; }
            public string CommandLine { get; set; }
            public string CurrentDirectory { get; set; }
            public string OSPlatform { get; set; }
            public string OSFullName { get; set; }
            public string OSVersion { get; set; }
            public string ClrVersion { get; set; }
            public bool IsInteractiveUser { get; set; }
            public bool Is64BitOS { get; set; }
            public bool Is64BitProcess { get; set; }
            public DateTime BootTime { get; set; }
            public TimeSpan Uptime { get; set; }

            public long WorkingSet { get; set; }
            public long MemoryLoad { get; set; }
            public long TotalPhysicalMemoryMB { get; set; }
            public long AvailPhysicalMemoryMB { get; set; }

            public List<string> FixedDiskInfo { get; set; }
            public List<string> NetAdapterInfo { get; set; }

            public string DisplayResolution { get; set; }

            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
            private class MEMORYSTATUSEX
            {
                public uint dwLength;
                public uint dwMemoryLoad;
                public ulong ullTotalPhys;
                public ulong ullAvailPhys;
                public ulong ullTotalPageFile;
                public ulong ullAvailPageFile;
                public ulong ullTotalVirtual;
                public ulong ullAvailVirtual;
                public ulong ullAvailExtendedVirtual;
                public MEMORYSTATUSEX()
                {
                    this.dwLength = (uint)Marshal.SizeOf(typeof(MEMORYSTATUSEX));
                }
            }
            [return: MarshalAs(UnmanagedType.Bool)]
            [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            static extern bool GlobalMemoryStatusEx([In, Out] MEMORYSTATUSEX lpBuffer);

            public SysInfo()
            {
                Initialize();
            }
            private void Initialize()
            {
                Microsoft.VisualBasic.Devices.Computer computer = new Microsoft.VisualBasic.Devices.Computer();

                MachineName = Environment.MachineName;
                UserName = Environment.UserName;
                Domain = Environment.UserDomainName;
                CommandLine = Environment.CommandLine;
                CurrentDirectory = Environment.CurrentDirectory;

                OSPlatform = computer.Info.OSPlatform;
                OSVersion = computer.Info.OSVersion;
                OSFullName = computer.Info.OSFullName;
                ClrVersion = String.Format("{0}", Environment.Version);
                IsInteractiveUser = Environment.UserInteractive;
                Is64BitOS = Environment.Is64BitOperatingSystem;
                Is64BitProcess = Environment.Is64BitProcess;
                WorkingSet = Environment.WorkingSet;

                try
                {
                    using (var uptime = new PerformanceCounter("System", "System Up Time"))
                    {
                        uptime.NextValue();       //Call this an extra time before reading its value
                        Uptime = TimeSpan.FromSeconds(uptime.NextValue());
                        BootTime = DateTime.Now.Subtract(Uptime);
                    }
                }
                catch (Exception)
                {
                }

                try
                {
                    MEMORYSTATUSEX memStatus = new MEMORYSTATUSEX();
                    if (GlobalMemoryStatusEx(memStatus))
                    {
                        MemoryLoad = Convert.ToInt64(memStatus.dwMemoryLoad);
                        TotalPhysicalMemoryMB = Convert.ToInt64(memStatus.ullTotalPhys / 1024 / 1024);
                        AvailPhysicalMemoryMB = Convert.ToInt64(memStatus.ullAvailPhys / 1024 / 1024);
                    }
                }
                catch (Exception)
                {
                }

                try
                {
                    DriveInfo[] drives = DriveInfo.GetDrives();
                    FixedDiskInfo = new List<string>();
                    foreach (var drive in drives)
                    {
                        try
                        {
                            if (drive.DriveType != DriveType.Fixed)
                                continue;
                            FixedDiskInfo.Add(String.Format("{0} Size: {1:n0}MB Free: {2:n0}MB", drive.Name, drive.TotalSize / 1024, drive.AvailableFreeSpace / 1024));
                        }
                        catch (Exception)
                        {
                        }
                    }
                }
                catch (Exception)
                {
                }

                try
                {
                    NetAdapterInfo = new List<string>();
                    NetworkInterface[] adapters = NetworkInterface.GetAllNetworkInterfaces();
                    foreach (NetworkInterface adapter in adapters)
                    {
                        if (adapter.OperationalStatus != OperationalStatus.Up)
                            continue;

                        IPInterfaceProperties properties = adapter.GetIPProperties();
                        foreach (var addr in properties.UnicastAddresses)
                        {
                            if (addr.Address.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
                            {
                                UnicastIPAddressInformation addrInfo = addr as UnicastIPAddressInformation;
                                NetAdapterInfo.Add(String.Format("{0}, {1}",
                                    adapter.Description,
                                    addrInfo.Address));
                            }
                        }
                    }
                }
                catch (Exception)
                {

                }

                DisplayResolution = String.Format("{0}x{1}", System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width, System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
            }

            public string GetJson()
            {
                JsonSerializerSettings customJsonSettings = new JsonSerializerSettings()
                {
                    DateFormatHandling = DateFormatHandling.IsoDateFormat,
                    DateTimeZoneHandling = DateTimeZoneHandling.Utc,
                    Formatting = Formatting.Indented
                };

                return JsonConvert.SerializeObject(this, customJsonSettings);
            }
        }
    }
}
