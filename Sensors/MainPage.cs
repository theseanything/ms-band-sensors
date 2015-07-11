
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
        private int heart = 0;


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



        private async void Run_Button_Click(object sender, RoutedEventArgs e)
        {

            ToggleRun.IsEnabled = false;

            this.viewModel.StatusMessage = "Loading .";

            file = await folder.CreateFileAsync("datanew.csv", CreationCollisionOption.ReplaceExisting);

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
                    heart_rate.ReadingChanged += HeartRate_ReadingChanged;

                    // GYROSCOPE
                    var gyroscope = bandClient.SensorManager.Gyroscope;
                    gyroscope.ReportingInterval = TimeSpan.FromMilliseconds(16);
                    gyroscope.ReadingChanged += Gyroscope_ReadingChanged;
                    Debug.WriteLine("3");

                    // ACCELEROMETER
                    var accelerometer = bandClient.SensorManager.Accelerometer;
                    accelerometer.ReportingInterval = TimeSpan.FromMilliseconds(16);
                    accelerometer.ReadingChanged += Accelerometer_ReadingChanged;
                    Debug.WriteLine("4");

                    //SKIN TEMP
                    var skinTemp = bandClient.SensorManager.SkinTemperature;
                    skinTemp.ReadingChanged +=skinTemp_ReadingChanged;

                    // Receive Accelerometer data for a while, then stop the subscription.
                    this.viewModel.StatusMessage = "Starting to record...";
                    await accelerometer.StartReadingsAsync();
                    await heart_rate.StartReadingsAsync();
                    await gyroscope.StartReadingsAsync();
                    await skinTemp.StartReadingsAsync();

            
                    Debug.WriteLine("5");
                    this.viewModel.StatusMessage = "Recording...";
                    await Task.Delay(TimeSpan.FromSeconds(interval));

               
                    await accelerometer.StopReadingsAsync();
                    await heart_rate.StopReadingsAsync();
                    await gyroscope.StopReadingsAsync();
                    await skinTemp.StopReadingsAsync();
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

        private async void skinTemp_ReadingChanged(object sender, BandSensorReadingEventArgs<IBandSkinTemperatureReading> e)
        {
            IBandSkinTemperatureReading skintemp = e.SensorReading;
            await Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
            {
                this.viewModel.StatusMessage = skintemp.Temperature.ToString();
            }).AsTask();
        }

        private async void Accelerometer_ReadingChanged(object sender, BandSensorReadingEventArgs<IBandAccelerometerReading> e)
        {
            IBandAccelerometerReading accel = e.SensorReading;
            await Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
            {
                data.Append(string.Format("{0:F2},{1:F2},{2:F2}", accel.AccelerationX, accel.AccelerationY, accel.AccelerationZ));
            }).AsTask();
        }

        private async void HeartRate_ReadingChanged(object sender, BandSensorReadingEventArgs<IBandHeartRateReading> e)
        {
            IBandHeartRateReading hr = e.SensorReading;
            await Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () => {
                heart = hr.HeartRate; 
            }).AsTask();
        }

        private async void Gyroscope_ReadingChanged(object sender, BandSensorReadingEventArgs<IBandGyroscopeReading> e)
        {
            IBandGyroscopeReading gyro = e.SensorReading;
            await Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
            {
                data.AppendLine(string.Format(",{0:F3},{1:F3},{2:F3},{3}", gyro.AngularVelocityX, gyro.AngularVelocityY, gyro.AngularVelocityZ, heart));
            }).AsTask();
        }

    }
}
