# Zero-Scale Caching Strategy

## Overview
When Cloud Run scales to zero, the first request triggers a "cold start" taking 3-8 seconds. A caching layer can serve content instantly while the container starts.

## Option 1: Cloudflare (Recommended for Cost)

### Setup Steps:
1. Add site to Cloudflare (free plan)
2. Update nameservers at domain registrar
3. Configure Page Rules:
   ```
   *graph-attract.io/*
   - Cache Level: Cache Everything
   - Edge Cache TTL: 4 hours
   ```

4. Install Cloudflare plugin in WordPress:
   ```dockerfile
   # Add to Dockerfile
   RUN cd /var/www/html/wp-content/plugins && \
       curl -O https://downloads.wordpress.org/plugin/cloudflare.latest-stable.zip && \
       unzip cloudflare.latest-stable.zip && rm cloudflare.latest-stable.zip
   ```

### Performance:
- **Cache Hit**: 10-50ms (from nearest Cloudflare edge)
- **Cache Miss**: 3-8s (cold start) + becomes cached
- **Effective Uptime**: 99.9%+ (Cloudflare serves even if Cloud Run is down)

### Cost: FREE

## Option 2: Google Cloud CDN

### Setup:
```bash
# Create NEG (Network Endpoint Group)
gcloud compute network-endpoint-groups create wp-cloud-run-neg \
  --region=us-central1 \
  --network-endpoint-type=serverless \
  --cloud-run-service=wp-cloud-run

# Create backend service
gcloud compute backend-services create wp-backend \
  --global \
  --enable-cdn \
  --cache-mode=CACHE_ALL_STATIC

# Create URL map
gcloud compute url-maps create wp-url-map \
  --default-service=wp-backend

# Create HTTPS proxy
gcloud compute target-https-proxies create wp-https-proxy \
  --url-map=wp-url-map \
  --ssl-certificates=wp-ssl-cert

# Create forwarding rule
gcloud compute forwarding-rules create wp-forwarding-rule \
  --global \
  --target-https-proxy=wp-https-proxy \
  --ports=443
```

### Performance:
- **Cache Hit**: 50-100ms
- **Cache Miss**: 3-8s (cold start)
- **Cost**: ~$18/month for load balancer

## Option 3: Always-On Minimum Instance

### Simple Alternative:
```bash
# Keep 1 instance always running
gcloud run services update wp-cloud-run \
  --region=us-central1 \
  --min-instances=1
```

### Performance:
- **All Requests**: 50-200ms (no cold starts)
- **Cost**: +~$10/month for always-on instance

## Recommended Architecture for Zero-Cost

```
[Visitor] → [Cloudflare Free] → [Cloud Run (0-2 instances)]
              ↓ (cached)             ↓ (only if needed)
           <50ms response         3-8s cold start
```

### Cloudflare Settings for WordPress:
1. **Page Rules**:
   - `/wp-admin/*` - Bypass Cache
   - `/*` - Cache Everything, 4 hour TTL

2. **Cache Settings**:
   - Browser Cache TTL: 4 hours
   - Always Online: Enabled
   - Auto Minify: HTML, CSS, JS

3. **WordPress Plugin Config**:
   - Automatic cache purge on post update
   - Optimize for WordPress

## Implementation Checklist

- [ ] Add domain to Cloudflare
- [ ] Update DNS nameservers
- [ ] Configure page rules
- [ ] Install Cloudflare WordPress plugin
- [ ] Test with Cloud Run at 0 instances
- [ ] Monitor cache hit ratio

## Testing Cold Starts

```bash
# Scale to zero
gcloud run services update wp-cloud-run --region=us-central1 --max-instances=0

# Wait 15 minutes for container to stop

# Test cold start time
time curl -I https://graph-attract.io

# Test cached response
time curl -I https://graph-attract.io
```

## Cache Warming Strategy

To prevent visitors from experiencing cold starts:

```bash
# Cron job to warm cache every 3 hours
0 */3 * * * curl -s https://graph-attract.io > /dev/null
```

## Monitoring

### Cloudflare Analytics (Free):
- Cache hit ratio
- Bandwidth saved
- Request geography

### Cloud Run Metrics:
- Cold start frequency
- Instance count
- Request latency

## Cost Comparison

| Setup | Monthly Cost | First Byte Time | Pros | Cons |
|-------|--------------|-----------------|------|------|
| No Cache + Min 0 | $0 | 3-8s | Lowest cost | Slow first visit |
| Cloudflare Free | $0 | 50ms cached / 3-8s miss | Fast + Free | Extra service |
| Cloud CDN | ~$18 | 100ms cached / 3-8s miss | Google integrated | Costs money |
| Min Instance = 1 | ~$10 | 50-200ms | Always fast | Always running |

## Recommendation

For graph-attract.io with budget constraints:
1. **Use Cloudflare Free tier**
2. **Cache everything except /wp-admin**
3. **Keep Cloud Run at 0-2 instances**
4. **Result**: Fast site, zero cold starts for most visitors, $0 additional cost