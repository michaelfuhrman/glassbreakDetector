classdef DETECT_PERFORMANCE
   properties
      T_total
      T_Noise_LabeledNoise
      T_Noise_LabeledSpeech
      T_Speech_LabeledNoise
      T_Speech_LabeledSpeech
      FalseTriggers
      Syllables_Total
      Syllables_Missed
      Syllables_Latency
   end
   methods
      function obj = DETECT_PERFORMANCE()
        obj.T_total=0;
        obj.T_Noise_LabeledNoise=0;
        obj.T_Noise_LabeledSpeech=0;
        obj.T_Speech_LabeledNoise=0;
        obj.T_Speech_LabeledSpeech=0;
        obj.FalseTriggers=0;
        obj.Syllables_Total=0;
        obj.Syllables_Missed=0;
        obj.Syllables_Latency=1;
      end

      function obj = plus(obj1,obj2)
        obj=DETECTOR_PERFORMANCE();
        obj.T_total=obj1.T_total+obj2.T_total;
        obj.T_Noise_LabeledNoise=obj1.T_Noise_LabeledNoise+obj2.T_Noise_LabeledNoise;
        obj.T_Noise_LabeledSpeech=obj1.T_Noise_LabeledSpeech+obj2.T_Noise_LabeledSpeech;
        obj.T_Speech_LabeledNoise=obj1.T_Speech_LabeledNoise+obj2.T_Speech_LabeledNoise;
        obj.T_Speech_LabeledSpeech=obj1.T_Speech_LabeledSpeech+obj2.T_Speech_LabeledSpeech;
        obj.FalseTriggers=obj1.FalseTriggers+obj2.FalseTriggers;
        obj.Syllables_Total=obj1.Syllables_Total+obj2.Syllables_Total;
        obj.Syllables_Missed=obj1.Syllables_Missed+obj2.Syllables_Missed;
        obj.Syllables_Latency=[obj1.Syllables_Latency; obj2.Syllables_Latency];
      end

      function FAR=FAR(obj)
        FAR = obj.T_Noise_LabeledSpeech / (obj.T_Noise_LabeledSpeech+obj.T_Noise_LabeledNoise);
      end

      function FRR=FRR(obj)
        FRR = obj.T_Speech_LabeledNoise / (obj.T_Speech_LabeledNoise+obj.T_Speech_LabeledSpeech);
      end

      function SyllableMissPercentage=SyllableMissPercentage(obj)
        SyllableMissPercentage=obj.Syllables_Missed/obj.Syllables_Total;
      end

      function MeanLatency=MeanLatency(obj)
        MeanLatency=mean(obj.Syllables_Latency);
      end

      function disp(obj)
         disp(['# of false triggers: ' num2str(obj.FalseTriggers) ...
               '; Events missed (%): ' num2str(obj.SyllableMissPercentage)]);
         disp(['Average event latency (s): ' num2str(obj.MeanLatency)]);
      end
   end
end
