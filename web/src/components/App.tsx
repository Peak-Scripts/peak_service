import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { useNuiEvent } from '../hooks/useNuiEvent';
import { Shield, AlertCircle } from 'lucide-react';
import './App.css';

interface CommunityServiceData {
  admin: string;
  remainingTasks: number;
  completedTasks: number;
  originalTasks: number;
  reason: string;
  locales?: Record<string, string>;
}

const App: React.FC = () => {
  const [data, setData] = React.useState<CommunityServiceData>({
    admin: '',
    remainingTasks: 0,
    completedTasks: 0,
    originalTasks: 0,
    reason: ''
  });
  const [locales, setLocales] = React.useState<Record<string, string>>({});

  useNuiEvent<CommunityServiceData>('updateServiceData', (serviceData) => {
    if (serviceData.locales) {
      setLocales(serviceData.locales);
    }
    setData({
      ...serviceData,
      originalTasks: serviceData.originalTasks,
      completedTasks: serviceData.completedTasks || 0
    });
  });

  return (
    <div className="absolute inset-0 flex items-end justify-end pb-8 pr-8">
      <Card className="bg-gray-900/95 text-white border border-white/5 animate-fade-up">
        <CardContent className="p-4 2xl:p-5 flex items-center gap-4 2xl:gap-6">
          <Card className="bg-white/5 border-0">
            <CardContent className="p-3 2xl:p-4 flex items-center gap-2 2xl:gap-3">
              <Shield className="w-3.5 h-3.5 2xl:w-4 2xl:h-4 text-white/70" />
              <div>
                <p className="text-[11px] 2xl:text-xs text-white/50">{locales.assigned_by || 'Assigned by'}</p>
                <p className="text-xs 2xl:text-sm font-medium">{locales.admin?.replace('%s', data.admin) || data.admin}</p>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/5 border-0">
            <CardContent className="p-3 2xl:p-4 flex items-center gap-2 2xl:gap-3">
              <AlertCircle className="w-3.5 h-3.5 2xl:w-4 2xl:h-4 text-white/70" />
              <div className="min-w-[200px]">
                <p className="text-[11px] 2xl:text-xs text-white/50">{locales.reason_label || 'Reason'}</p>
                <p className="text-xs 2xl:text-sm font-medium truncate max-w-[300px]">
                  {locales.reason?.replace('%s', data.reason) || data.reason}
                </p>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/5 border-0">
            <CardContent className="p-3 2xl:p-4 flex items-center gap-2 2xl:gap-3">
              <div>
                <p className="text-[11px] 2xl:text-xs text-white/50">{locales.progress_label || 'Progress'}</p>
                <p className="text-xs 2xl:text-sm font-medium">
                  {locales.tasks?.replace('%d', data.completedTasks.toString()).replace('%d', data.originalTasks.toString()) || 
                    `${data.completedTasks}/${data.originalTasks} tasks`}
                </p>
              </div>
            </CardContent>
          </Card>
        </CardContent>
      </Card>
    </div>
  );
};

export default App;
