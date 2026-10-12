import { Body, Controller, Get, Param, Put } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { SettingValues } from '../../app/setting-values';
import { UpdateSetting } from '../../app/update-setting';
import { type Setting } from '../../domain/settings';
import { adminErrors } from './error-map';

type SettingView = components['schemas']['Setting'];

function settingView(s: Setting): SettingView {
  return {
    key: s.key,
    value: s.value,
    type: s.type as SettingView['type'],
    description: s.description,
    updatedAt: s.updatedAt.toISOString(),
    ...(s.updatedBy === null ? {} : { updatedBy: s.updatedBy }),
  };
}

/** Platform settings (A-10). */
@Controller('v1/admin/settings')
@MapErrors(adminErrors)
export class SettingsController {
  constructor(
    private readonly settings: SettingValues,
    private readonly updateSetting: UpdateSetting,
  ) {}

  @Get()
  @RequirePermission('settings:read')
  async list(): Promise<components['schemas']['SettingList']> {
    return { items: (await this.settings.list()).map(settingView) };
  }

  @Put(':key')
  @RequirePermission('settings:manage')
  async update(
    @CurrentPrincipal() me: Principal,
    @Param('key') key: string,
    @Body() body: components['schemas']['SettingUpdate'],
  ): Promise<SettingView> {
    return settingView(await this.updateSetting.execute(me.accountId, key, body.value));
  }
}
