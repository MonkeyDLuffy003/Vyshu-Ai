import React, { useState } from 'react';
import { Calculator, Mic, Volume2, RotateCcw, Delete, Equal } from 'lucide-react';
import { audioService } from '../../services/audioService';

export const VoiceCalculator: React.FC = () => {
  const [display, setDisplay] = useState('0');
  const [equation, setEquation] = useState('');
  const [history, setHistory] = useState<string[]>([]);
  const [isListeningVoice, setIsListeningVoice] = useState(false);

  const handleDigit = (d: string) => {
    audioService.playSound('click');
    setDisplay((prev) => (prev === '0' ? d : prev + d));
  };

  const handleOperator = (op: string) => {
    audioService.playSound('click');
    setEquation(display + ' ' + op + ' ');
    setDisplay('0');
  };

  const handleClear = () => {
    audioService.playSound('click');
    setDisplay('0');
    setEquation('');
  };

  const handleBackspace = () => {
    audioService.playSound('click');
    setDisplay((prev) => (prev.length > 1 ? prev.slice(0, -1) : '0'));
  };

  const handleCalculate = () => {
    audioService.playSound('send');
    try {
      const fullExp = equation + display;
      const sanitized = fullExp
        .replace(/×/g, '*')
        .replace(/÷/g, '/')
        .replace(/[^0-9\+\-\*\/\.\(\)]/g, '');

      // eslint-disable-next-line no-eval
      const result = Function(`'use strict'; return (${sanitized})`)();
      const formatted = Number.isInteger(result) ? result.toString() : result.toFixed(3);

      const record = `${fullExp} = ${formatted}`;
      setHistory((prev) => [record, ...prev.slice(0, 9)]);
      setDisplay(formatted);
      setEquation('');

      // Voice read-out
      audioService.speak(`The result is ${formatted}`, 'en-IN');
    } catch {
      setDisplay('Error');
    }
  };

  // Voice speech calculation listener
  const handleVoiceCalculation = () => {
    if (isListeningVoice) {
      audioService.stopListening();
      setIsListeningVoice(false);
      return;
    }

    setIsListeningVoice(true);
    audioService.startListening(
      (text, isFinal) => {
        if (isFinal) {
          setIsListeningVoice(false);
          // Try parse math
          const sanitized = text
            .toLowerCase()
            .replace(/times/g, '*')
            .replace(/multiplied by/g, '*')
            .replace(/divided by/g, '/')
            .replace(/plus/g, '+')
            .replace(/minus/g, '-')
            .replace(/[^0-9\+\-\*\/\.\(\)]/g, '');

          try {
            if (sanitized && /[\+\-\*\/]/.test(sanitized)) {
              // eslint-disable-next-line no-eval
              const res = Function(`'use strict'; return (${sanitized})`)();
              const formatted = Number.isInteger(res) ? res.toString() : res.toFixed(2);
              setDisplay(formatted);
              setHistory((prev) => [`${text} = ${formatted}`, ...prev]);
              audioService.speak(`The result of ${text} is ${formatted}`, 'en-IN');
            } else {
              setDisplay(text);
            }
          } catch {
            audioService.speak(`Could not calculate: ${text}`, 'en-IN');
          }
        }
      },
      (err) => {
        setIsListeningVoice(false);
      }
    );
  };

  return (
    <div className="space-y-4 max-w-sm mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
            <Calculator className="w-4 h-4" /> Voice &amp; Math Calculator
          </h2>
          <p className="text-xs text-slate-400">Speak equations or use the smart keypad</p>
        </div>

        <button
          onClick={handleVoiceCalculation}
          className={`text-xs px-3 py-1.5 rounded-xl font-bold flex items-center gap-1.5 transition active:scale-95 shadow-md ${
            isListeningVoice
              ? 'bg-rose-500 text-white animate-pulse'
              : 'bg-cyan-400 text-slate-950 hover:bg-cyan-300 shadow-cyan-500/20'
          }`}
        >
          <Mic className="w-3.5 h-3.5" />
          {isListeningVoice ? 'Listening...' : 'Voice Math'}
        </button>
      </div>

      {/* Calculator Screen */}
      <div className="p-4 bg-[#0b0b16] border border-cyan-500/30 rounded-3xl glow-cyan space-y-1">
        <div className="text-right text-xs font-mono text-cyan-400/80 min-h-[18px]">{equation}</div>
        <div className="text-right text-3xl font-mono font-black text-white tracking-wider truncate">
          {display}
        </div>
      </div>

      {/* Calculator Keypad */}
      <div className="grid grid-cols-4 gap-2.5">
        <button
          onClick={handleClear}
          className="p-3.5 rounded-2xl bg-slate-800 text-rose-400 font-bold text-sm hover:bg-slate-700 transition active:scale-95"
        >
          C
        </button>
        <button
          onClick={handleBackspace}
          className="p-3.5 rounded-2xl bg-slate-800 text-slate-300 font-bold text-sm hover:bg-slate-700 transition active:scale-95 flex items-center justify-center"
        >
          <Delete className="w-4 h-4" />
        </button>
        <button
          onClick={() => handleOperator('%')}
          className="p-3.5 rounded-2xl bg-slate-800 text-cyan-400 font-bold text-sm hover:bg-slate-700 transition active:scale-95"
        >
          %
        </button>
        <button
          onClick={() => handleOperator('÷')}
          className="p-3.5 rounded-2xl bg-cyan-500/20 text-cyan-300 font-bold text-base hover:bg-cyan-500/30 transition active:scale-95"
        >
          ÷
        </button>

        {['7', '8', '9'].map((n) => (
          <button
            key={n}
            onClick={() => handleDigit(n)}
            className="p-3.5 rounded-2xl bg-[#0e1422] text-white font-bold text-sm hover:bg-slate-800 transition active:scale-95"
          >
            {n}
          </button>
        ))}
        <button
          onClick={() => handleOperator('×')}
          className="p-3.5 rounded-2xl bg-cyan-500/20 text-cyan-300 font-bold text-base hover:bg-cyan-500/30 transition active:scale-95"
        >
          ×
        </button>

        {['4', '5', '6'].map((n) => (
          <button
            key={n}
            onClick={() => handleDigit(n)}
            className="p-3.5 rounded-2xl bg-[#0e1422] text-white font-bold text-sm hover:bg-slate-800 transition active:scale-95"
          >
            {n}
          </button>
        ))}
        <button
          onClick={() => handleOperator('-')}
          className="p-3.5 rounded-2xl bg-cyan-500/20 text-cyan-300 font-bold text-base hover:bg-cyan-500/30 transition active:scale-95"
        >
          -
        </button>

        {['1', '2', '3'].map((n) => (
          <button
            key={n}
            onClick={() => handleDigit(n)}
            className="p-3.5 rounded-2xl bg-[#0e1422] text-white font-bold text-sm hover:bg-slate-800 transition active:scale-95"
          >
            {n}
          </button>
        ))}
        <button
          onClick={() => handleOperator('+')}
          className="p-3.5 rounded-2xl bg-cyan-500/20 text-cyan-300 font-bold text-base hover:bg-cyan-500/30 transition active:scale-95"
        >
          +
        </button>

        <button
          onClick={() => handleDigit('0')}
          className="col-span-2 p-3.5 rounded-2xl bg-[#0e1422] text-white font-bold text-sm hover:bg-slate-800 transition active:scale-95"
        >
          0
        </button>
        <button
          onClick={() => handleDigit('.')}
          className="p-3.5 rounded-2xl bg-[#0e1422] text-white font-bold text-sm hover:bg-slate-800 transition active:scale-95"
        >
          .
        </button>
        <button
          onClick={handleCalculate}
          className="p-3.5 rounded-2xl bg-cyan-400 text-slate-950 font-black text-lg hover:bg-cyan-300 transition active:scale-95 shadow-md shadow-cyan-500/20 flex items-center justify-center"
        >
          <Equal className="w-5 h-5" />
        </button>
      </div>

      {/* History */}
      {history.length > 0 && (
        <div className="pt-2">
          <div className="text-[11px] font-semibold text-slate-400 uppercase mb-1.5">Calculation History</div>
          <div className="bg-[#0b0b16] border border-slate-800 rounded-2xl p-2.5 space-y-1 max-h-24 overflow-y-auto font-mono text-xs text-slate-300">
            {history.map((h, i) => (
              <div key={i} className="flex justify-between py-0.5 border-b border-slate-800/40 last:border-none">
                <span>{h}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
