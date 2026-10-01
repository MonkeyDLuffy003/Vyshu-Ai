import React, { useState, useEffect } from 'react';
import { SplashScreen } from './components/SplashScreen';
import { OnboardingPermissions } from './components/OnboardingPermissions';
import { ChatScreen } from './components/ChatScreen';
import { VirtualRoom } from './components/VirtualRoom';
import { ControlScreen } from './components/ControlScreen';
import { VaultScreen } from './components/VaultScreen';
import { BottomNav } from './components/BottomNav';
import { FeaturesDrawer } from './components/FeaturesDrawer';
import { storageService } from './services/storageService';

export const App: React.FC = () => {
  const [showSplash, setShowSplash] = useState(true);
  const [isOnboarded, setIsOnboarded] = useState(false);
  const [activeTab, setActiveTab] = useState<'vyshu' | 'room' | 'control' | 'vault'>('vyshu');
  const [isFeaturesHubOpen, setIsFeaturesHubOpen] = useState(false);
  const [initialFeatureTab, setInitialFeatureTab] = useState<any>('languages');
  const [chatPromptQuery, setChatPromptQuery] = useState<string | undefined>(undefined);

  useEffect(() => {
    setIsOnboarded(storageService.isOnboardingComplete());
  }, []);

  const handleSplashDone = () => {
    setShowSplash(false);
  };

  const handleOnboardingDone = () => {
    setIsOnboarded(true);
  };

  const handleOpenHub = (tabName: string = 'languages') => {
    setInitialFeatureTab(tabName);
    setIsFeaturesHubOpen(true);
  };

  if (showSplash) {
    return <SplashScreen onComplete={handleSplashDone} />;
  }

  if (!isOnboarded) {
    return <OnboardingPermissions onComplete={handleOnboardingDone} />;
  }

  return (
    <div className="flex flex-col h-screen w-screen bg-[#05050f] text-slate-100 overflow-hidden select-none">
      {/* Active Screen View */}
      <div className="flex-1 flex flex-col overflow-hidden pb-16">
        {activeTab === 'vyshu' && (
          <ChatScreen
            onOpenFeatures={handleOpenHub}
            onOpenVirtualRoom={() => setActiveTab('room')}
            externalPrompt={chatPromptQuery}
            onClearExternalPrompt={() => setChatPromptQuery(undefined)}
          />
        )}

        {activeTab === 'room' && (
          <VirtualRoom
            onOpenFeatures={handleOpenHub}
            onSwitchToChat={() => setActiveTab('vyshu')}
          />
        )}

        {activeTab === 'control' && <ControlScreen />}

        {activeTab === 'vault' && <VaultScreen />}
      </div>

      {/* Persistent Bottom Navigation */}
      <BottomNav
        currentTab={activeTab}
        onSelectTab={(tab) => setActiveTab(tab)}
        onOpenHub={() => handleOpenHub('languages')}
      />

      {/* Multi-Tool Feature Hub Drawer */}
      <FeaturesDrawer
        isOpen={isFeaturesHubOpen}
        onClose={() => setIsFeaturesHubOpen(false)}
        initialTab={initialFeatureTab}
        onAskVyshu={(query) => {
          setActiveTab('vyshu');
          setChatPromptQuery(query);
        }}
      />
    </div>
  );
};

export default App;
