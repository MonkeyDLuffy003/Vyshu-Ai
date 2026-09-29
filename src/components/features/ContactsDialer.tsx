import React, { useState } from 'react';
import {
  Phone,
  PhoneCall,
  Search,
  UserPlus,
  Volume2,
  MessageCircle,
  Trash2,
  Sparkles,
  PhoneIncoming,
} from 'lucide-react';
import { storageService } from '../../services/storageService';
import { ContactItem } from '../../types';
import { audioService } from '../../services/audioService';

export const ContactsDialer: React.FC = () => {
  const [contacts, setContacts] = useState<ContactItem[]>(storageService.getContacts());
  const [search, setSearch] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);
  const [newName, setNewName] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [incomingCallName, setIncomingCallName] = useState<string | null>(null);

  const filtered = contacts.filter(
    (c) =>
      c.name.toLowerCase().includes(search.toLowerCase()) ||
      c.phone.toLowerCase().includes(search.toLowerCase())
  );

  const handleAddContact = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim() || !newPhone.trim()) return;

    const newContact: ContactItem = {
      id: Date.now().toString(),
      name: newName.trim(),
      phone: newPhone.trim(),
      avatarColor: ['#00ccff', '#ec4899', '#3b82f6', '#10b981', '#8b5cf6'][
        contacts.length % 5
      ],
    };

    const updated = [newContact, ...contacts];
    setContacts(updated);
    storageService.saveContacts(updated);
    setShowAddForm(false);
    setNewName('');
    setNewPhone('');
    audioService.playSound('send');
  };

  const handleDelete = (id: string) => {
    const updated = contacts.filter((c) => c.id !== id);
    setContacts(updated);
    storageService.saveContacts(updated);
  };

  const handleDial = (contact: ContactItem) => {
    audioService.playSound('click');
    audioService.speak(`Calling ${contact.name} now.`, 'en-IN');
    window.location.href = `tel:${contact.phone.replace(/\s+/g, '')}`;
  };

  const handleWhatsApp = (contact: ContactItem) => {
    audioService.playSound('click');
    const cleanNumber = contact.phone.replace(/[^0-9]/g, '');
    window.open(`https://wa.me/${cleanNumber}`, '_blank');
  };

  // Caller ID voice announcement simulation
  const handleAnnounceCaller = (contact: ContactItem) => {
    setIncomingCallName(contact.name);
    audioService.playSound('alert');
    audioService.speak(
      `Teja, incoming call from ${contact.name}, ${contact.phone}. Tap to accept or dismiss.`,
      'en-IN',
      () => {
        setTimeout(() => setIncomingCallName(null), 3000);
      }
    );
  };

  return (
    <div className="space-y-4">
      {/* Incoming Call Simulation Banner */}
      {incomingCallName && (
        <div className="p-4 bg-emerald-500/20 border border-emerald-500/40 rounded-2xl flex items-center justify-between animate-bounce">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-full bg-emerald-400 text-slate-950 flex items-center justify-center animate-pulse">
              <PhoneIncoming className="w-5 h-5" />
            </div>
            <div>
              <div className="text-xs text-emerald-300 font-semibold uppercase tracking-wider">
                Vyshu Caller-ID Announcement
              </div>
              <div className="text-sm font-bold text-white">{incomingCallName} is calling...</div>
            </div>
          </div>
          <button
            onClick={() => setIncomingCallName(null)}
            className="text-xs px-3 py-1.5 rounded-lg bg-emerald-500 text-slate-950 font-bold"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-sm font-bold text-cyan-400 tracking-wide uppercase flex items-center gap-2">
            <Phone className="w-4 h-4" /> Phone &amp; Gmail Contacts Dialer
          </h2>
          <p className="text-xs text-slate-400">
            Outbound dialing &amp; voice caller-ID announcements
          </p>
        </div>

        <button
          onClick={() => setShowAddForm(!showAddForm)}
          className="text-xs px-3 py-1.5 rounded-xl bg-cyan-400 text-slate-950 font-bold hover:bg-cyan-300 flex items-center gap-1.5 transition active:scale-95 shadow-md shadow-cyan-500/20"
        >
          <UserPlus className="w-3.5 h-3.5" /> Add Contact
        </button>
      </div>

      {/* Search Input */}
      <div className="relative">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search contacts by name or phone..."
          className="w-full bg-[#0e1422] border border-slate-800 rounded-xl px-3.5 py-2 pl-9 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-cyan-400"
        />
        <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
      </div>

      {/* Add Contact Form */}
      {showAddForm && (
        <form onSubmit={handleAddContact} className="bg-[#0e1422] border border-cyan-500/30 rounded-2xl p-4 space-y-3 animate-fade-in">
          <div className="text-xs font-bold text-cyan-400 uppercase tracking-wider">Save New Contact</div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="text-[11px] text-slate-400 block mb-1">Full Name</label>
              <input
                type="text"
                required
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                placeholder="e.g. Manikanta Teja"
                className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-cyan-400"
              />
            </div>
            <div>
              <label className="text-[11px] text-slate-400 block mb-1">Phone Number</label>
              <input
                type="tel"
                required
                value={newPhone}
                onChange={(e) => setNewPhone(e.target.value)}
                placeholder="+91 98765 43210"
                className="w-full bg-[#05050f] border border-slate-800 rounded-xl px-3 py-2 text-xs text-slate-200 focus:outline-none focus:border-cyan-400 font-mono"
              />
            </div>
          </div>
          <div className="flex justify-end gap-2 pt-1">
            <button
              type="button"
              onClick={() => setShowAddForm(false)}
              className="px-3 py-1.5 rounded-xl bg-slate-800 text-slate-400 text-xs font-semibold hover:bg-slate-700"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-1.5 rounded-xl bg-cyan-400 text-slate-950 text-xs font-bold hover:bg-cyan-300"
            >
              Save Contact
            </button>
          </div>
        </form>
      )}

      {/* Contacts List */}
      <div className="space-y-2.5 max-h-[50vh] overflow-y-auto pr-1">
        {filtered.map((contact) => (
          <div
            key={contact.id}
            className="p-3.5 bg-[#0b0b16] border border-slate-800 rounded-2xl flex items-center justify-between hover:border-slate-700 transition"
          >
            <div className="flex items-center space-x-3">
              <div
                className="w-10 h-10 rounded-2xl flex items-center justify-center font-bold text-white text-sm"
                style={{ backgroundColor: contact.avatarColor || '#00ccff' }}
              >
                {contact.name.slice(0, 2).toUpperCase()}
              </div>
              <div>
                <div className="text-xs font-bold text-slate-100">{contact.name}</div>
                <div className="text-[11px] font-mono text-slate-400">{contact.phone}</div>
              </div>
            </div>

            <div className="flex items-center space-x-1.5">
              <button
                onClick={() => handleAnnounceCaller(contact)}
                title="Test Voice Caller-ID Announcement"
                className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 transition"
              >
                <Volume2 className="w-3.5 h-3.5" />
              </button>

              <button
                onClick={() => handleWhatsApp(contact)}
                title="Chat on WhatsApp"
                className="p-2 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 transition"
              >
                <MessageCircle className="w-3.5 h-3.5" />
              </button>

              <button
                onClick={() => handleDial(contact)}
                title="Dial Call"
                className="p-2 rounded-xl bg-cyan-500/20 hover:bg-cyan-500/30 text-cyan-300 font-bold transition"
              >
                <PhoneCall className="w-3.5 h-3.5" />
              </button>

              <button
                onClick={() => handleDelete(contact.id)}
                title="Delete"
                className="p-2 rounded-xl bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 transition"
              >
                <Trash2 className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
