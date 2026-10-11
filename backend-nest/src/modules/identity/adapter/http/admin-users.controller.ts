import { Body, Controller, Get, HttpCode, Inject, Param, Patch, Post, Put } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { AdminUsers } from '../../app/admin-users';
import { RoleEditor } from '../../app/role-editor';
import { identityErrors } from './identity-errors';
import { adminUserView, roleView } from './views';

type Schemas = components['schemas'];

/** Admin users (A-10). */
@Controller('v1/admin/admin-users')
@MapErrors(identityErrors)
export class AdminUsersController {
  constructor(@Inject(AdminUsers) private readonly admins: AdminUsers) {}

  @Get()
  @RequirePermission('admin_user:manage')
  async listAdminUsers(): Promise<Schemas['AdminUserList']> {
    return { items: (await this.admins.list()).map(adminUserView) };
  }

  @Post()
  @RequirePermission('admin_user:manage')
  @HttpCode(201)
  async inviteAdminUser(
    @Body() body: Schemas['AdminUserInvite'],
  ): Promise<Schemas['AdminUserInvited']> {
    const { admin, temporaryPassword } = await this.admins.create(body);
    return { user: adminUserView(admin), temporaryPassword };
  }

  @Patch(':adminUserId')
  @RequirePermission('admin_user:manage')
  async updateAdminUser(
    @Param('adminUserId') adminId: string,
    @Body() body: Schemas['AdminUserUpdate'],
  ): Promise<Schemas['AdminUser']> {
    return adminUserView(await this.admins.update({ adminId, ...body }));
  }
}

/** The role editor (A-10). */
@Controller('v1/admin/roles')
@MapErrors(identityErrors)
export class RolesController {
  constructor(@Inject(RoleEditor) private readonly roles: RoleEditor) {}

  @Get()
  @RequirePermission('role:manage')
  async listRoles(): Promise<Schemas['RoleList']> {
    const c = await this.roles.list();
    return {
      items: c.roles.map(roleView),
      allPermissions: c.allPermissions,
      allScreens: c.allScreens,
    };
  }

  @Put(':role')
  @RequirePermission('role:manage')
  async updateRole(
    @Param('role') role: string,
    @Body() body: Schemas['RoleUpdate'],
  ): Promise<Schemas['RoleDefinition']> {
    return roleView(await this.roles.update({ role, ...body }));
  }
}
