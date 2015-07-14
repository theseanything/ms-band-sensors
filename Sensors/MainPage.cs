
using Microsoft.Band;
using Microsoft.Band.Sensors;
using System;
using System.Threading.Tasks;
using System.IO;
using System.Text;
using System.Diagnostics;
using Windows.UI.Core;
using Windows.UI.Xaml;
using Windows.Storage;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Input;

namespace Sensors
{

    partial class MainPage
    {
        private App viewModel;

        // file storage and string setup

        private StorageFolder folder = ApplicationData.Current.LocalFolder;
        private StorageFile file;
        private StringBuilder data = new StringBuilder();
        private int interval = 20;
        string filename = "data";
        private int heart = 0;
        Stopwatch gyrow = new Stopwatch();
        Stopwatch accw = new Stopwatch();
        Stopwatch hrw = new Stopwatch();

        Stopwatch skinw = new Stopwatch();


        private void TimeInterval_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (!String.IsNullOrEmpty(TimeInterval.Text) && Convert.ToInt32(TimeInterval.Text) < 3600 && Convert.ToInt32(TimeInterval.Text) > 0)
            {
                ToggleRun.IsEnabled = true;
                interval = Convert.ToInt32(TimeInterval.Text);
            }
            else
            {
                ToggleRun.IsEnabled = false;
            }
            
        }

        private void Filename_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (!String.IsNullOrEmpty(TimeInterval.Text) && !String.IsNullOrWhiteSpace(TimeInterval.Text))
            {
                ToggleRun.IsEnabled = true;
            }
            else
            {
                ToggleRun.IsEnabled = false;
            }

        }



        private async void Run_Button_Click(object sender, RoutedEventArgs e)
        {
            this.viewModel.StatusMessage = "Loading .";

            filename = Filename.Text;

            file = await folder.CreateFileAsync(filename + ".csv", CreationCollisionOption.GenerateUniqueName);

            this.viewModel.StatusMessage = "Loading ..";

            try
            {
                // Get the list of Microsoft Bands paired to the phone.
                IBandInfo[] pairedBands = await BandClientManager.Instance.GetBandsAsync();
                this.viewModel.StatusMessage = "Loading ...";

                if (pairedBands.Length < 1)
                {
                    this.viewModel.StatusMessage = "This sample app requires a Microsoft Band paired to your device. Also make sure that you have the latest firmware installed on your Band, as provided by the latest Microsoft Health app.";
                    //ToggleRun.IsEnabled = true;
                    return;
                }
                Debug.WriteLine("1");
                this.viewModel.StatusMessage = "Loading ....";

                // Connect to Microsoft Band.
                using (IBandClient bandClient = await BandClientManager.Instance.ConnectAsync(pairedBands[0]))
                {

                    // Subscribe to Accelerometer data.
                    Debug.WriteLine("2");
                    this.viewModel.StatusMessage = "Connecting ...";
                    
                    //HEART RATE
                    var heart_rate = bandClient.SensorManager.HeartRate;
                    if (heart_rate.GetCurrentUserConsent() != UserConsent.Granted)
                    {
                        await heart_rate.RequestUserConsentAsync();
                    }
                    heart_rate.ReadingChanged += (o, args) =>
                    {
                        Debug.WriteLine("hrr:{0}", hrw.ElapsedMilliseconds);
                        hrw.Restart();
                        IBandHeartRateReading hr = args.SensorReading;
                        heart = hr.HeartRate;
                    };

                    // GYROSCOPE
                    var gyroscope = bandClient.SensorManager.Gyroscope;
                    gyroscope.ReportingInterval = TimeSpan.FromMilliseconds(16);

                    gyroscope.ReadingChanged += (o, args) => {
                        Debug.WriteLine("gry:{0}", gyrow.ElapsedMilliseconds);
                        gyrow.Restart();
                        IBandGyroscopeReading gyro = args.SensorReading;
                        data.AppendLine(string.Format(",{0:F3},{1:F3},{2:F3},{3}", gyro.AngularVelocityX, gyro.AngularVelocityY, gyro.AngularVelocityZ, heart));

                    };
                    Debug.WriteLine("3");

                    // ACCELEROMETER
                    var accelerometer = bandClient.SensorManager.Accelerometer;
                    accelerometer.ReportingInterval = TimeSpan.FromMilliseconds(16);
                    accelerometer.ReadingChanged += (o, args) =>
                    {
                        Debug.WriteLine("acc:{0}", accw.ElapsedMilliseconds);
                        accw.Restart();
                        IBandAccelerometerReading accel = args.SensorReading;
                        data.Append(string.Format("{0:F2},{1:F2},{2:F2}", accel.AccelerationX, accel.AccelerationY, accel.AccelerationZ));

                    };
                    Debug.WriteLine("4");

                    //SKIN TEMP
                    var skinTemp = bandClient.SensorManager.SkinTemperature;
                    skinTemp.ReadingChanged += (o, args) =>
                    {
                        Debug.WriteLine("ski:{0}", skinw.ElapsedMilliseconds);
                        skinw.Restart();
                    };

                    // Receive Accelerometer data for a while, then stop the subscription.
                    this.viewModel.StatusMessage = "Starting to record...";
                    accw.Start();
                    await accelerometer.StartReadingsAsync();
                    hrw.Start();
                    await heart_rate.StartReadingsAsync();
                    gyrow.Start();
                    await gyroscope.StartReadingsAsync();
                    skinw.Start();
                    await skinTemp.StartReadingsAsync();

            
                    Debug.WriteLine("5");
                    this.viewModel.StatusMessage = "Recording...";
                    await Task.Delay(TimeSpan.FromSeconds(interval));

               
                    await accelerometer.StopReadingsAsync();
                    accw.Stop();
                    await heart_rate.StopReadingsAsync();
                    hrw.Stop();
                    await gyroscope.StopReadingsAsync();
                    gyrow.Stop();
                    await skinTemp.StopReadingsAsync();
                    skinw.Stop();
                    Debug.WriteLine("6");

                    await FileIO.WriteTextAsync(file, data.ToString());
                    this.viewModel.StatusMessage = "File Saved.";
                    Debug.WriteLine("7");
                }
            }
            catch (Exception ex)
            {
                this.viewModel.StatusMessage = ex.ToString();
            }
            Debug.WriteLine("8");
            ToggleRun.IsEnabled = true;
        }

    }
}
