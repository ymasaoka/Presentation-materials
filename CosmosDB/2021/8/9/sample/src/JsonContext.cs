using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;

namespace SampleCosmosApp
{
    public class RGB
    {
        public string id { get; set; }
        public int x { get; set; }
        public int y { get; set; }
        public int R { get; set; }
        public int G { get; set; }
        public int B { get; set; }
    }

    public class JsonContext
    {
        public IList<RGB> RGBList { get; set; }

        public async Task InitializeRGBData()
        {
            // var jsonArray = string.Empty;
            using (FileStream fs = new FileStream("./data/MonaLiza.json", FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                using (StreamReader sr = new StreamReader(fs, System.Text.Encoding.UTF8))
                {
                    var jsonStr = await sr.ReadToEndAsync();
                    RGBList = JsonSerializer.Deserialize<List<RGB>>(jsonStr);
                }
            }
        }

        public async Task InitializeRGBMono()
        {
            // var jsonArray = string.Empty;
            using (FileStream fs = new FileStream("./data/MonaLiza_Mono.json", FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                using (StreamReader sr = new StreamReader(fs, System.Text.Encoding.UTF8))
                {
                    var jsonStr = await sr.ReadToEndAsync();
                    RGBList = JsonSerializer.Deserialize<List<RGB>>(jsonStr);
                }
            }
        }
    }
}