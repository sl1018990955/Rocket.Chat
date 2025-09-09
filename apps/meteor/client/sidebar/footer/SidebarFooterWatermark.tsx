import { Box } from '@rocket.chat/fuselage';
import type { ReactElement } from 'react';
import { useTranslation } from 'react-i18next';

import { useLicense, useLicenseName } from '../../hooks/useLicense';

export const SidebarFooterWatermark = (): ReactElement | null => {
	return (
		<Box pi={16} pbe={8}>
			<Box fontScale='micro' color='hint' pbe={4}>
				欢迎使用HT.Chat
			</Box>
		</Box>
	);
};
