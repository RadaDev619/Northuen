# Northuen Pilot Table Field Lists

## Runner Locations

Northuen currently stores live runner GPS in `driver_live_locations`. If you prefer the app wording, treat this as the `runner_locations` table.

| Field | Type | Notes |
| --- | --- | --- |
| `driver_id` | `uuid` | Runner/driver ID. Foreign key to `drivers(id)`. |
| `order_id` | `uuid` | Pick & Drop order ID. Foreign key to `pickdrop_orders(id)`. |
| `lat` | `numeric(10,7)` | Latest runner latitude. |
| `lng` | `numeric(10,7)` | Latest runner longitude. |
| `heading` | `numeric(6,2)` | Optional movement direction in degrees. |
| `speed` | `numeric(8,2)` | Optional speed from phone GPS. |
| `created_at` | `timestamp` | First location row creation time. |
| `updated_at` | `timestamp` | Latest live GPS update time. |

Recommended constraints/indexes:
- Primary key: `driver_id, order_id`
- Index: `order_id, updated_at desc`
- Index: `driver_id, updated_at desc`

## Notifications

The production table is `notifications`.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `uuid` | Primary key. |
| `user_id` | `uuid` | Recipient user. Foreign key to `users(id)`. |
| `title` | `varchar(140)` | Short notification title. |
| `message` | `text` | Notification body. |
| `read` | `boolean` | Whether user has opened/read it. |
| `type` | `varchar(40)` | Example: `ORDER_STATUS`, `ADMIN`, `PAYMENT`, `SYSTEM`. |
| `target_role` | `varchar(20)` | Optional admin targeting metadata: `CUSTOMER`, `DRIVER`, `VENDOR`, `ADMIN`. |
| `sent_by_admin_id` | `uuid` | Optional admin sender. Foreign key to `users(id)`. |
| `priority` | `integer` | Higher priority can be surfaced first later. |
| `read_at` | `timestamp` | When the user marked it read. |
| `created_at` | `timestamp` | Created time. |
| `updated_at` | `timestamp` | Updated time. |

Recommended indexes:
- `user_id, read, created_at desc`
- `target_role`
- `type`
