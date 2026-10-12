import { Inject, Injectable } from '@nestjs/common';
import { covers } from '../domain/area';
import { type Point } from '../domain/customer';
import { LAUNCH_AREA, type LaunchArea } from '../port/peers';

/** The launch-area check (C35). */
@Injectable()
export class ServiceArea {
  constructor(@Inject(LAUNCH_AREA) private readonly area: LaunchArea) {}

  /** Reports whether `p` lies inside the launch area. */
  async covers(p: Point): Promise<boolean> {
    return covers(await this.area.geoJson(), p);
  }
}
