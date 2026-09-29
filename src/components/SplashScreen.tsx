import React, { useEffect, useState } from 'react';
import { Sparkles, Shield, Cpu } from 'lucide-react';

interface SplashScreenProps {
  onComplete: () => void;
}

export const SplashScreen: React.FC<SplashScreenProps> = ({ onComplete }) => {
  const [progress, setProgress] = useState(10);

  useEffect(() => {
    const timer = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(timer);
          setTimeout(onComplete, 400);
          return 100;
        }
        return prev + 18;
      });
    }, 150);

    return () => clearInterval(timer);
  }, [onComplete]);

  return (
    <div className="fixed inset-0 z-50 bg-[#05050f] flex flex-col items-center justify-center p-6 text-slate-100 select-none">
      <div className="text-center space-y-6 max-w-sm w-full">
        {/* Futuristic glowing avatar/logo with APK outside logo */}
        <div className="relative mx-auto flex items-center justify-center gap-3">
          <div className="relative w-24 h-24 rounded-2xl border-2 border-cyan-400/80 p-1 bg-[#0b0b16] shadow-2xl glow-cyan flex items-center justify-center overflow-hidden">
            <img
              src="/assets/images/vyshu_logo.png"
              alt="Vyshu AI App Logo"
              className="w-full h-full object-contain rounded-xl"
            />
          </div>
          <div className="relative w-24 h-24 rounded-2xl border-2 border-purple-500/80 p-1 bg-[#0b0b16] shadow-2xl glow-purple flex items-center justify-center overflow-hidden">
            <img
              src="/assets/images/vyshu_avatar.png"
              alt="Vyshu AI - Her Picture"
              className="w-full h-full object-cover rounded-xl"
            />
          </div>
        </div>

        <div>
          <h1 className="text-3xl font-extrabold tracking-wider text-white">VYSHU AI</h1>
          <p className="text-xs text-cyan-400 font-mono tracking-widest uppercase mt-1">
            AI Smart Assistant &amp; Secretary
          </p>
        </div>

        {/* Loading Progress Bar */}
        <div className="space-y-2">
          <div className="w-full bg-slate-900 border border-slate-800 rounded-full h-2 overflow-hidden">
            <div
              className="bg-gradient-to-r from-cyan-400 to-purple-500 h-2 rounded-full transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
          <div className="flex justify-between text-[11px] font-mono text-slate-500">
            <span>Calibrating Neural Modules...</span>
            <span className="text-cyan-400">{progress}%</span>
          </div>
        </div>
      </div>
    </div>
  );
};
