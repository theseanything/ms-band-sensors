
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
using Microsoft.Band.Notifications;

namespace Sensors
{

    partial class MainPage
    {
        private App viewModel;

        // file storage and string setup

        private StorageFile file;
        private StringBuilder data = new StringBuilder();
        private int interval = 20;
        string filename = "data";
        private int heart = 0;
        private double x = 0;
        private double y = 0;
        private double z = 0;


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

            string datePatt = @"M-d-hh-mm";
            string date = DateTime.Now.ToString(datePatt);

            filename = Filename.Text;

            file = await DownloadsFolder.CreateFileAsync(filename + " " + date + ".csv", CreationCollisionOption.GenerateUniqueName);

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
                this.viewModel.StatusMessage = "Loading ....";

                // Connect to Microsoft Band.
                using (IBandClient bandClient = await BandClientManager.Instance.ConnectAsync(pairedBands[0]))
                {

                    this.viewModel.StatusMessage = "Connecting ...";

                    // ACCELEROMETER
                    var accelerometer = bandClient.SensorManager.Accelerometer;
                    accelerometer.ReportingInterval = TimeSpan.FromMilliseconds(16);
                    accelerometer.ReadingChanged += (o, args) =>
                    {
                        IBandAccelerometerReading accel = args.SensorReading;
                        x = accel.AccelerationX;
                        y = accel.AccelerationY;
                        z = accel.AccelerationZ;

                    };       
             
                    //HEART RATE
                    var heart_rate = bandClient.SensorManager.HeartRate;
                    if (heart_rate.GetCurrentUserConsent() != UserConsent.Granted)
                    {
                        await heart_rate.RequestUserConsentAsync();
                    }
                    heart_rate.ReadingChanged += (o, args) =>
                    {
                    
                        IBandHeartRateReading hr = args.SensorReading;
                        heart = hr.HeartRate;
                    };

                    // GYROSCOPE
                    var gyroscope = bandClient.SensorManager.Gyroscope;
                    gyroscope.ReportingInterval = TimeSpan.FromMilliseconds(16);

                    gyroscope.ReadingChanged += (o, args) => {
            
                        IBandGyroscopeReading gyro = args.SensorReading;
                        data.AppendLine(string.Format("{0:F2},{1:F2},{2:F2},{3:F2},{4:F2},{5:F2},{6}", x, y, z, gyro.AngularVelocityX, gyro.AngularVelocityY, gyro.AngularVelocityZ, heart));

                    };



                    // Start to record
                    this.viewModel.StatusMessage = "Starting to record...";

                    
                    await accelerometer.StartReadingsAsync();
                    await gyroscope.StartReadingsAsync();
                    await heart_rate.StartReadingsAsync();

                    try
                    {
                        await bandClient.NotificationManager.VibrateAsync(VibrationType.NotificationOneTone);
                    }
                    catch (BandException ex)
                    {
                        this.viewModel.StatusMessage = ex.ToString();
                    }

                    this.viewModel.StatusMessage = "Recording...";
                    await Task.Delay(TimeSpan.FromSeconds(interval));

               
                    await accelerometer.StopReadingsAsync();
                    await gyroscope.StopReadingsAsync();
                    await heart_rate.StopReadingsAsync();

                    try
                    {
                        await bandClient.NotificationManager.VibrateAsync(VibrationType.NotificationOneTone);
                    }
                    catch (BandException ex)
                    {
                        this.viewModel.StatusMessage = ex.ToString();
                    }

                    await FileIO.WriteTextAsync(file, data.ToString());
                    data.Clear();
                    this.viewModel.StatusMessage = "File Saved.";
                }
            }
            catch (Exception ex)
            {
                this.viewModel.StatusMessage = ex.ToString();
            }
            ToggleRun.IsEnabled = true;
        }

    }
}
